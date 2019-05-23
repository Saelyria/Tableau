import UIKit

/**
 An enum describing rules for which sections cells from a section can be moved to.
 */
public enum CellMovementPolicy<S: TableViewSection> {
    /// The cells from this section can only be moved to the sections in the given array. Note that this array must
    /// explicitly include the section the cell came from to be able to move the cell within its original section.
    case toSectionsIn([S])
    
    case toSectionsPassing((S) -> Bool)
    /// The cells from this section can be moved to any section on the table.
    case toAnySection
}

/**
 An enum that describes the reason a cell in a section was deleted.
 */
public enum CellDeletionReason<S: TableViewSection> {
    /// The existing cell was moved to the given section and row.
    case moved(toSection: S, row: Int)
    /// The cell was deleted via an editing control.
    case editing
}

/**
 An enum that describes where a cell inserted in a section came from.
 */
public enum CellInsertionReason<S: TableViewSection> {
    /// An existing cell was moved from the given section and row.
    case moved(fromSection: S, row: Int)
    /// A new cell was created and inserted via an editing control.
    case editing
}

/// An object that stores the various handlers the binder uses.
class _TableViewBindingHandlers<S: TableViewSection> {
    /// A class that holds the handlers for different 'section scopes' for a type of callback.
    class HandlerSet<H> {
        fileprivate(set) lazy var namedSection: [S: H] = { [:] }()
        fileprivate(set) var dynamicSections: H?
        fileprivate(set) var anySection: H? {
            willSet {
                if !self.allowAnySection { fatalError("This type of handler does not allow binding to 'any section'.") }
            }
        }
        
        var hasHandler: Bool {
            return (!self.namedSection.isEmpty
                || self.dynamicSections != nil
                || (self.allowAnySection && self.anySection != nil))
        }
        
        fileprivate var allowAnySection: Bool
        
        fileprivate init(allowAnySection: Bool) {
            self.allowAnySection = allowAnySection
        }
    }
    
    // Cell handlers
    
    // Closures that will update the data on the binder's data model when 'refresh' is called
    var modelUpdaters: [() -> Void] = []
    
    // Closures to call to dequeue a cell in a section.
    lazy var cellProviders: HandlerSet<(S, UITableView, IndexPath) -> UITableViewCell> = {
        HandlerSet(allowAnySection: false)
    }()

    // Closures to call to get the height for a cell in a section.
    lazy var cellHeightProviders: HandlerSet<(S, Int) -> CGFloat> = {
        HandlerSet(allowAnySection: true)
    }()
    
    // Closures to call to get the estimated height for a cell in a section.
    lazy var cellEstimatedHeightProviders: HandlerSet<(S, Int) -> CGFloat> = {
        HandlerSet(allowAnySection: true)
    }()
    
    // A function for each section that determines whether the model for a given row was updated. In most cases, this
    // will be a wrapper around `Equatable` conformance. These functions return nil if it can't compare the objects
    // given to it (e.g. weren't the right type).
    lazy var itemEqualityCheckers: HandlerSet<(Any, Any) -> Bool?> = {
        HandlerSet(allowAnySection: false)
    }()
    
    // The prefetch behaviour for a section.
    lazy var prefetchBehaviors: HandlerSet<PrefetchBehavior> = {
        HandlerSet(allowAnySection: false)
    }()
    
    // Closures to be called to handle prefetching data.
    lazy var prefetchHandlers: HandlerSet<(Int) -> Void> = {
        HandlerSet(allowAnySection: false)
    }()
    
    // MARK: -
    
    // Blocks to call to dequeue a header in a section.
    lazy var headerViewProviders: HandlerSet<(S, UITableView) -> UITableViewHeaderFooterView?> = {
        HandlerSet(allowAnySection: false)
    }()

    // Blocks to call to get the height for a header.
    lazy var headerHeightProviders: HandlerSet<(S) -> CGFloat> = {
        HandlerSet(allowAnySection: true)
    }()

    // Blocks to call to get the estimated height for a header.
    lazy var headerEstimatedHeightProviders: HandlerSet<(S) -> CGFloat> = {
        HandlerSet(allowAnySection: true)
    }()
    
    // MARK: -
    
    // Blocks to call to dequeue a footer in a section.
    lazy var footerViewProviders: HandlerSet<(S, UITableView) -> UITableViewHeaderFooterView?> = {
        HandlerSet(allowAnySection: false)
    }()

    // Blocks to call to get the height for a section footer.
    lazy var footerHeightProviders: HandlerSet<(S) -> CGFloat> = {
        HandlerSet(allowAnySection: true)
    }()

    // Blocks to call to get the estimated height for a section footer.
    lazy var footerEstimatedHeightProviders: HandlerSet<(S) -> CGFloat> = {
        HandlerSet(allowAnySection: true)
    }()

    // MARK: -
    
    // Blocks to call when a cell is tapped in a section.
    lazy var cellTappedHandlers: HandlerSet<(S, Int, UITableViewCell) -> Void> = {
        HandlerSet(allowAnySection: true)
    }()

    // Blocks to call when a cell is dequeued in a section.
    lazy var cellDequeuedHandlers: HandlerSet<(S, Int, UITableViewCell) -> Void> = {
        HandlerSet(allowAnySection: true)
    }()
    
    // Handlers for custom cell view events in a section. Each section has another dictionary under it where the key is
    // a string describing a cell type that has view events, and the value is the handler associated with it that is
    // called whenever a cell of that type in the section emits an event.
    lazy var viewEventHandlers: HandlerSet<[String :(S, Int, UITableViewCell, _ event: Any) -> Void]> = {
        HandlerSet(allowAnySection: false)
    }()
    
    // MARK: -
    
    // Blocks to call to determine the editing style of a cell in a section.
    lazy var cellEditingStyleProviders: HandlerSet<(S, Int) -> UITableViewCell.EditingStyle> = {
        HandlerSet(allowAnySection: false)
    }()
    
    lazy var cellDeletedHandlers: HandlerSet<(S, Int, CellDeletionReason<S>) -> Void> = {
        HandlerSet(allowAnySection: false)
    }()
    
    lazy var cellInsertedHandlers: HandlerSet<(S, Int, CellInsertionReason<S>) -> Void> = {
        HandlerSet(allowAnySection: false)
    }()
    
    // Blocks to call to determine whether a cell in a section is movable.
    lazy var cellMovableProviders: HandlerSet<(S, Int) -> Bool> = {
        HandlerSet(allowAnySection: false)
    }()
    
    lazy var cellMovementPolicies: HandlerSet<CellMovementPolicy<S>> = {
        HandlerSet(allowAnySection: false)
    }()
}

extension _TableViewBindingHandlers {
    func add<H>(
        _ handler: H,
        toHandlerSetAt keyPath: ReferenceWritableKeyPath<_TableViewBindingHandlers<S>, HandlerSet<H>>,
        forScope affectedSectionScope: SectionBindingScope<S>)
    {
        // the 'view event handlers' are further held under a dictionary for each cell type, so need to be handled
        // differently.
        if keyPath == \_TableViewBindingHandlers.viewEventHandlers {
            let handlerSet = self.viewEventHandlers
            guard let dict = handler as? [String :(S, Int, UITableViewCell, _ event: Any) -> Void] else { fatalError() }
            switch affectedSectionScope {
            case .forNamedSections(let sections):
                for section in sections {
                    if handlerSet.namedSection[section] == nil {
                        handlerSet.namedSection[section] = [:]
                    }
                    handlerSet.namedSection[section]?.merge(dict, uniquingKeysWith: { $1 })
                }
            case .forAllUnnamedSections:
                if handlerSet.dynamicSections == nil {
                    handlerSet.dynamicSections = [:]
                }
                handlerSet.dynamicSections?.merge(dict, uniquingKeysWith: { $1 })
            case .forAnySection:
                fatalError("Not allowed")
            }
        } else {
            let handlerSet: HandlerSet<H> = self[keyPath: keyPath]
            switch affectedSectionScope {
            case .forNamedSections(let sections):
                for section in sections {
                    handlerSet.namedSection[section] = handler
                }
            case .forAllUnnamedSections:
                handlerSet.dynamicSections = handler
            case .forAnySection:
                handlerSet.anySection = handler
            }
        }
    }
}
