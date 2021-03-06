import UIKit


class SettingViewController: BaseTableViewController {

    enum SettingItemType {
        case accounts
        case browser, baiduOCRConfig, logout, fullScreenBack, shakeFeedback, notifications
        case ignoreWords, recognizeClipboardLink, appearance
        case tabSort
        case floor, readMark, newReplyReset
    }
    
    struct SettingItem {
        var title: String
        var type: SettingItemType
        var rightType: RightType
    }

    // MARK: - Propertys

    private var sections: [[SettingItem]] = [
        [
            SettingItem(title: "使用 Safari 浏览网页", type: .browser, rightType: .switch),
            SettingItem(title: "识别剪切板链接", type: .recognizeClipboardLink, rightType: .switch),
            SettingItem(title: "全屏返回手势", type: .fullScreenBack, rightType: .switch),
//            SettingItem(title: "夜间模式", type: .nightMode, rightType: .switch),
            SettingItem(title: "摇一摇反馈", type: .shakeFeedback, rightType: .switch)
        ],
        [
            SettingItem(title: "显示设置", type: .appearance, rightType: .arrow),
            SettingItem(title: "主题屏蔽", type: .ignoreWords, rightType: .arrow),
            SettingItem(title: "节点排序", type: .tabSort, rightType: .arrow),
            SettingItem(title: "@用户时带楼层号(@devjoe #1)", type: .floor, rightType: .switch),
            SettingItem(title: "已读状态标记", type: .readMark, rightType: .switch),
        ],
//        [
//            SettingItem(title: "OCR 配置", type: .baiduOCRConfig, rightType: .arrow),
//            SettingItem(title: "消息推送", type: .notifications, rightType: .arrow),
//        ],
        [
            SettingItem(title: "退出账号", type: .logout, rightType: .none)
        ]
    ]
    
    private let newReadReset: SettingItem = SettingItem(title: "当有新回复时，恢复未读状态", type: .newReplyReset, rightType: .switch)

    // MARK: - View Life Cycle

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Preference.shared.isEnableReadMark {
            sections[1].append(newReadReset)
        }

        tableView.register(cellWithClass: BaseTableViewCell.self)

//        if AccountModel.isLogin {
//            let section = [SettingItem(title: "账号管理", type: .accounts, rightType: .arrow)]
//            sections.insert(section, at: 0)
//        }
    }

}

// MARK: - UITableViewDelegate
extension SettingViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return AccountModel.isLogin ? sections.count : sections.count - 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
        cell.selectionStyle = .none
        
        let item = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.title
        cell.textLabel?.textAlignment = item.type == .logout ? .center : .left
        cell.textLabel?.textColor = item.type == .logout ? .red : ThemeStyle.style.value.titleColor
        switch item.type {
        case .browser:
            cell.switchView.isOn = Preference.shared.useSafariBrowser
        case .fullScreenBack:
            cell.switchView.isOn = Preference.shared.enableFullScreenGesture
        case .shakeFeedback:
            cell.switchView.isOn = Preference.shared.shakeFeedback
        case .floor:
            cell.switchView.isOn = Preference.shared.atMemberAddFloor
        case .recognizeClipboardLink:
            cell.switchView.isOn = Preference.shared.recognizeClipboardLink
        case .readMark:
            cell.switchView.isOn = Preference.shared.isEnableReadMark
        case .newReplyReset:
            cell.switchView.isOn = Preference.shared.isEnableNewReadReset
        default:
            break
        }
        cell.rightType = item.rightType
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? BaseTableViewCell else { return }
        cell.switchView.setOn(!cell.switchView.isOn, animated: true)
        let item = sections[indexPath.section][indexPath.row]

        if item.rightType == .switch {
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
        }
        
        switch item.type {
        case .accounts:
            navigationController?.pushViewController(AccountsViewController(), animated: true)
        case .browser:
            Preference.shared.useSafariBrowser = cell.switchView.isOn
        case .fullScreenBack:
            Preference.shared.enableFullScreenGesture = cell.switchView.isOn
        case .shakeFeedback:
            Preference.shared.shakeFeedback = cell.switchView.isOn
        case .recognizeClipboardLink:
            Preference.shared.recognizeClipboardLink = cell.switchView.isOn
        case .readMark:
            Preference.shared.isEnableReadMark = cell.switchView.isOn
            if cell.switchView.isOn {
                sections[1].append(newReadReset)
                tableView.insertRows(at: [IndexPath(item: tableView.numberOfRows(inSection: 1), section: 1)], with: .automatic)
            } else {
                sections[1].removeLast()
                tableView.deleteRows(at: [IndexPath(item: tableView.numberOfRows(inSection: 1) - 1, section: 1)], with: .automatic)
            }
        case .newReplyReset:
            Preference.shared.isEnableNewReadReset = cell.switchView.isOn
        case .tabSort:
            let sortVC = TabSortViewController()
            navigationController?.pushViewController(sortVC, animated: true)
        case .baiduOCRConfig:
            let vc = OCRConfigViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .logout:
            presentLoginVC()
            tableView.reloadData()
        case .ignoreWords:
            let iwVC = IgnoreWordsViewController()
            navigationController?.pushViewController(iwVC, animated: true)
        case .appearance:
            let appearanceVC = AppearanceViewController()
            appearanceVC.title = item.title
            navigationController?.pushViewController(appearanceVC, animated: true)
        case .notifications:
            guard AccountModel.isLogin else {
                HUD.showError("该功能需要先登录")
                return
            }
            let viewController = NotificationViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .floor:
            Preference.shared.atMemberAddFloor = cell.switchView.isOn
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
