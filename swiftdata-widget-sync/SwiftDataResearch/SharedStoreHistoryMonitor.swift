import CoreData
import Foundation
import SwiftData
import WidgetKit

struct SharedStoreChangeSummary: Equatable, Sendable {
    let transactionCount: Int
    let insertedCount: Int
    let updatedCount: Int
    let deletedCount: Int
    let operationLogCount: Int

    var hasChanges: Bool {
        transactionCount > 0
    }

    var operationDescription: String {
        guard hasChanges else {
            return "Store change notification received, no new history"
        }

        return "History: \(transactionCount) transaction(s), notes +\(insertedCount) ~\(updatedCount) -\(deletedCount), ops \(operationLogCount)"
    }
}

@ModelActor
actor SharedStoreHistoryMonitor {
    private static let historyTokenKey = "SwiftDataResearch.historyToken"

    func processNewTransactions() -> SharedStoreChangeSummary {
        SharedLog.history.debug("Processing SwiftData transaction history")
        let previousToken = loadHistoryToken()
        SharedLog.history.debug("History token exists before fetch: \(previousToken != nil, privacy: .public)")

        let transactions = fetchTransactions(after: previousToken)
        let summary = summarize(transactions)

        if let newToken = transactions.last?.token {
            saveHistoryToken(newToken)
            SharedLog.history.debug("Saved latest history token")
        } else {
            SharedLog.history.debug("No new history token to save")
        }

        if let previousToken {
            do {
                try deleteTransactions(before: previousToken)
                SharedLog.history.debug("Deleted history before previous token")
            } catch {
                SharedLog.history.error("Failed to delete old history: \(error.localizedDescription, privacy: .public)")
            }
        }

        SharedLog.history.info("Processed history: \(summary.operationDescription, privacy: .public)")

        if summary.hasChanges {
            WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
            SharedLog.history.debug("Requested widget timeline reload after processing history")
        }

        return summary
    }

    private func loadHistoryToken() -> DefaultHistoryToken? {
        guard let tokenData = UserDefaults.standard.data(forKey: Self.historyTokenKey) else {
            SharedLog.history.debug("No stored history token found")
            return nil
        }

        do {
            return try JSONDecoder().decode(DefaultHistoryToken.self, from: tokenData)
        } catch {
            SharedLog.history.error("Failed to decode stored history token: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func saveHistoryToken(_ token: DefaultHistoryToken) {
        guard let tokenData = try? JSONEncoder().encode(token) else {
            SharedLog.history.error("Failed to encode history token")
            return
        }

        UserDefaults.standard.set(tokenData, forKey: Self.historyTokenKey)
    }

    private func fetchTransactions(after token: DefaultHistoryToken?) -> [DefaultHistoryTransaction] {
        var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()

        if let token {
            descriptor.predicate = #Predicate { transaction in
                transaction.token > token
            }
        }

        do {
            let transactions = try modelContext.fetchHistory(descriptor)
            SharedLog.history.info("Fetched \(transactions.count, privacy: .public) history transaction(s)")
            return transactions
        } catch {
            SharedLog.history.error("Failed to fetch history transactions: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func summarize(_ transactions: [DefaultHistoryTransaction]) -> SharedStoreChangeSummary {
        var insertedCount = 0
        var updatedCount = 0
        var deletedCount = 0
        var operationLogCount = 0

        for transaction in transactions {
            SharedLog.history.info(
                "Transaction id=\(transaction.transactionIdentifier, privacy: .public), store=\(transaction.storeIdentifier, privacy: .public), author=\(transaction.author ?? "nil", privacy: .public), bundle=\(transaction.bundleIdentifier, privacy: .public), process=\(transaction.processIdentifier, privacy: .public), timestamp=\(transaction.timestamp.formatted(.iso8601), privacy: .public), changes=\(transaction.changes.count, privacy: .public)"
            )

            for change in transaction.changes {
                switch change {
                case .insert(_ as DefaultHistoryInsert<ResearchNote>):
                    insertedCount += 1
                case .update(_ as DefaultHistoryUpdate<ResearchNote>):
                    updatedCount += 1
                case .delete(_ as DefaultHistoryDelete<ResearchNote>):
                    deletedCount += 1
                case .insert(_ as DefaultHistoryInsert<OperationLog>):
                    operationLogCount += 1
                default:
                    break
                }
            }
        }

        SharedLog.history.debug("Summarized history changes: notes +\(insertedCount, privacy: .public) ~\(updatedCount, privacy: .public) -\(deletedCount, privacy: .public), operation logs \(operationLogCount, privacy: .public)")

        return SharedStoreChangeSummary(
            transactionCount: transactions.count,
            insertedCount: insertedCount,
            updatedCount: updatedCount,
            deletedCount: deletedCount,
            operationLogCount: operationLogCount
        )
    }

    private func deleteTransactions(before token: DefaultHistoryToken) throws {
        var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        descriptor.predicate = #Predicate { transaction in
            transaction.token < token
        }

        let context = ModelContext(modelContainer)
        try context.deleteHistory(descriptor)
    }
}
