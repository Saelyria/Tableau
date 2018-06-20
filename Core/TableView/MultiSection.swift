import UIKit

/// Protocol that allows us to have Reactive extensions
public protocol MultiSectionTableViewBindResultProtocol {
    associatedtype C: UITableViewCell
    associatedtype S: TableViewSection
}

/**
 A throwaway object created when a table view binder's `onSections(_:)` method is called. This object declares a number
 of methodss that take a binding handler and give it to the original table view binder to store for callback.
 */
public class MultiSectionTableViewBindResult<C: UITableViewCell, S: TableViewSection>: MultiSectionTableViewBindResultProtocol {
    internal let binder: SectionedTableViewBinder<S>
    internal let sections: [S]
    internal var sectionBindResults: [S: SingleSectionTableViewBindResult<C, S>] = [:]
    
    internal init(binder: SectionedTableViewBinder<S>, sections: [S]) {
        self.binder = binder
        self.sections = sections
    }
    
    /**
     Bind the given cell type to the declared sections, creating them based on the view models from a given observable.
     */
    @discardableResult
    public func bind<NC, T: NSObject>(cellType: NC.Type, byObserving keyPath: KeyPath<T, [S: [NC.ViewModel]]>, on provider: T)
    -> MultiSectionTableViewBindResult<NC, S> where NC: UITableViewCell & ViewModelBindable & ReuseIdentifiable {
        let sections = self.sections
        let token = provider.observe(keyPath, options: [.initial, .new]) { [weak binder = self.binder] (_, value) in
            let allViewModels: [S: [NC.ViewModel]]? = value.newValue
            for section in sections {
                guard let sectionViewModels: [NC.ViewModel] = allViewModels?[section] else {
                    assertionFailure("ERROR: No cell view models array given for the section '\(section)'")
                    return
                }
                binder?.sectionCellViewModels[section] = sectionViewModels
                binder?.reload(section: section)
            }
        }
        self.binder.observationTokens.append(token)

        return MultiSectionTableViewBindResult<NC, S>(binder: self.binder, sections: self.sections)
    }
    
    /**
     Bind the given cell type to the declared sections, creating them based on the view models created from a given
     array of models mapped to view models by a given function.
     */
    @discardableResult
    public func bind<NC, NM, T: NSObject>(cellType: NC.Type, byObserving keyPath: KeyPath<T, [S: [NM]]>, on provider: T, mapToViewModelsWith mapToViewModel: @escaping (NM) -> NC.ViewModel)
    -> MultiSectionModelTableViewBindResult<NC, S, NM> where NC: UITableViewCell & ViewModelBindable & ReuseIdentifiable {
        let sections = self.sections
        let token = provider.observe(keyPath, options: [.initial, .new]) { [weak binder = self.binder] (_, value) in
            let allModels: [S: [NM]]? = value.newValue
            for section in sections {
                guard let sectionModels: [NM] = allModels?[section] else {
                    assertionFailure("ERROR: No cell models array given for the section '\(section)'")
                    return
                }
                let sectionViewModels: [NC.ViewModel] = sectionModels.map(mapToViewModel)
                binder?.sectionCellModels[section] = sectionModels
                binder?.sectionCellViewModels[section] = sectionViewModels
                binder?.reload(section: section)
            }
        }
        self.binder.observationTokens.append(token)
        
        return MultiSectionModelTableViewBindResult<NC, S, NM>(binder: self.binder, sections: self.sections)
    }
    
    /**
     Bind the given cell type to the declared sections, creating a cell for each item in the given observable array of
     models.
     
     Using this method allows a convenient mapping between the raw model objects that each cell in your table
     represents and the cells. When binding with this method, various other event binding methods (most notably the
     `onTapped` event method) can have their handlers be passed in the associated model (cast to the same type as the
     models observable type) along with the row and cell.
     
     When using this method, you pass in an observable array of your raw models for each section in a dictionary. Each
     section being bound to must have an observable array of models in the dictionary. From there, the binder will
     handle dequeuing of your cells based on the observable models array for each section. It is also expected that,
     when using this method, you will also use an `onCellDequeue` event handler to configure the cell, where you are
     given the model and the dequeued cell.
     */
    @discardableResult
    public func bind<NC, NM, T: NSObject>(cellType: NC.Type, byObserving keyPath: KeyPath<T, [S: [NM]]>, on provider: T)
    -> MultiSectionModelTableViewBindResult<NC, S, NM> where NC: UITableViewCell & ReuseIdentifiable {
        let sections = self.sections
        let token = provider.observe(keyPath, options: [.initial, .new]) { [weak binder = self.binder] (_, value) in
            let allModels: [S: [NM]]? = value.newValue
            for section in sections {
                guard let sectionModels: [NM] = allModels?[section] else {
                    assertionFailure("ERROR: No cell models array given for the section '\(section)'")
                    return
                }
                binder?.sectionCellModels[section] = sectionModels
                binder?.reload(section: section)
            }
        }
        self.binder.observationTokens.append(token)
        
        return MultiSectionModelTableViewBindResult<NC, S, NM>(binder: self.binder, sections: self.sections)
    }
    
    /**
     Bind the given header type to the declared section with the given observable for their view models.
     */
    @discardableResult
    public func bind<H>(headerType: H.Type, viewModels: [S: H.ViewModel]) -> MultiSectionTableViewBindResult<C, S>
    where H: UITableViewHeaderFooterView & ViewModelBindable & ReuseIdentifiable {
        for section in self.sections {
            guard let sectionViewModel = viewModels[section] else {
                fatalError("No header view model given for the section '\(section)'")
            }
            let sectionBindResult = self.bindResult(for: section)
            sectionBindResult.bind(headerType: headerType, viewModel: sectionViewModel)
        }
        
        return self
    }
    
    /**
     Add a handler to be called whenever a cell is dequeued in the declared sections.
     */
    @discardableResult
    public func configureCell(_ handler: @escaping (_ section: S, _ row: Int, _ dequeuedCell: C) -> Void) -> MultiSectionTableViewBindResult<C, S> {
        for section in self.sections {
            let bindResult: SingleSectionTableViewBindResult<C, S> = self.bindResult(for: section)
            bindResult.configureCell({ row, cell in
                handler(section, row, cell)
            })
        }
        return self
    }
    
    /**
     Add a handler to be called whenever a cell in the declared sections is tapped.
     */
    @discardableResult
    public func onTapped(_ handler: @escaping (_ section: S, _ row: Int, _ tappedCell: C) -> Void) -> MultiSectionTableViewBindResult<C, S> {
        for section in self.sections {
            let bindResult: SingleSectionTableViewBindResult<C, S> = self.bindResult(for: section)
            bindResult.onTapped({ row, cell in
                handler(section, row, cell)
            })
        }
        return self
    }
    
    /**
     Add a callback handler to provide the cell height for cells in the declared sections.
     */
    @discardableResult
    public func cellHeight(_ handler: @escaping (_ section: S, _ row: Int) -> CGFloat) -> MultiSectionTableViewBindResult<C, S> {
        for section in self.sections {
            let bindResult: SingleSectionTableViewBindResult<C, S> = self.bindResult(for: section)
            bindResult.cellHeight({ row in
                handler(section, row)
            })
        }
        return self
    }
    
    /**
     Add a callback handler to provide the estimated cell height for cells in the declared sections.
     */
    @discardableResult
    public func estimatedCellHeight(_ handler: @escaping (_ section: S, _ row: Int) -> CGFloat) -> MultiSectionTableViewBindResult<C, S> {
        for section in self.sections {
            let bindResult: SingleSectionTableViewBindResult<C, S> = self.bindResult(for: section)
            bindResult.estimatedCellHeight({ row in
                handler(section, row)
            })
        }
        return self
    }
    
    internal func bindResult(`for` section: S) -> SingleSectionTableViewBindResult<C, S> {
        if let bindResult = self.sectionBindResults[section] {
            return bindResult
        } else {
            let bindResult = SingleSectionTableViewBindResult<C, S>(binder: self.binder, section: section)
            self.sectionBindResults[section] = bindResult
            return bindResult
        }
    }
}