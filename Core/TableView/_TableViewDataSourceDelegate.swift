import UIKit

/// An internal class that acts as the de facto data source / delegate to a binder's table view.
class _TableViewDataSourceDelegate<SectionEnum: TableViewSection>: NSObject, UITableViewDataSource, UITableViewDelegate {
    private weak var binder: SectionedTableViewBinder<SectionEnum>!
    
    init(binder: SectionedTableViewBinder<SectionEnum>) {
        self.binder = binder
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.binder.displayedSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.binder.displayedSections[section]
        if let models = self.binder.sectionCellModels[section] {
            return models.count
        } else if let models = self.binder.sectionCellViewModels[section] {
            return models.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = self.binder.displayedSections[section]
        return self.binder.sectionHeaderTitles[section]
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section = self.binder.displayedSections[section]
        return self.binder.sectionFooterTitles[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = self.binder.displayedSections[indexPath.section]
        guard let dequeueBlock = self.binder.sectionCellDequeueBlocks[section] else { return UITableViewCell() }

        let cell = dequeueBlock(tableView, indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = self.binder.displayedSections[indexPath.section]
        if let estimatedHeightBlock = self.binder.sectionEstimatedCellHeightBlocks[section] {
            return estimatedHeightBlock(indexPath.row)
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = self.binder.displayedSections[indexPath.section]
        if let heightBlock = self.binder.sectionCellHeightBlocks[section] {
            return heightBlock(indexPath.row)
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection sectionInt: Int) -> UIView? {
        let section = self.binder.displayedSections[sectionInt]
        if let dequeueBlock = self.binder.sectionHeaderDequeueBlocks[section] {
            let header: UITableViewHeaderFooterView? = dequeueBlock(tableView, sectionInt)
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = self.binder.displayedSections[indexPath.section]
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        self.binder.sectionCellTappedCallbacks[section]?(indexPath.row, cell)
    }
}
