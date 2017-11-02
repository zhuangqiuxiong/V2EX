import UIKit
import NSObject_Rx

class TwoStepVerificationViewController: BaseViewController, AccountService {

    // MARK: UI

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "你的 V2EX 账号已经开启了两步验证，请输入验证码继续"
        view.font = UIFont.boldSystemFont(ofSize: 25)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.text = "出于安全考虑，当你开启了两步验证功能之后，那么你将需要每两周输入一次你的两步验证码"
        view.textColor = UIColor.black.withAlphaComponent(0.7)
        view.font = UIFont.systemFont(ofSize: 14)
        view.numberOfLines = 0
        view.textAlignment = .center
        return view
    }()

    private lazy var captchaTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入验证器（Authenticator）中的验证码"
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        //        view.setCornerRadius = 5
        view.textColor = Theme.Color.globalColor
        view.font = UIFont.systemFont(ofSize: 16)
        view.addLeftTextPadding(10)
        view.clearButtonMode = .whileEditing
        view.keyboardType = .numberPad
        view.delegate = self
        view.becomeFirstResponder()
        return view
    }()

    private lazy var nextBtn: UIButton = {
        let view = UIButton()
        view.setTitle("继续", for: .normal)
        view.backgroundColor = Theme.Color.globalColor
        //        view.setCornerRadius = 5
        return view
    }()

    private var forgotForm: LoginForm?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func setupSubviews() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close"), style: .plain) { [weak self] in
            self?.dismiss()
        }
        
        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "bj"))

        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: view.frame.width, height: view.frame.height)

        view.addSubviews(
            blurView,
            titleLabel,
            subtitleLabel,
            captchaTextField,
            nextBtn
        )
    }

    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.top.equalToSuperview().offset(view.height * 0.2)
        }

        subtitleLabel.snp.makeConstraints {
            $0.left.right.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
        }

        captchaTextField.snp.makeConstraints {
            $0.left.right.equalTo(titleLabel)
            $0.height.equalTo(50)
            $0.top.equalToSuperview().offset(view.height * 0.4)
        }

        nextBtn.snp.makeConstraints {
            $0.left.right.height.equalTo(captchaTextField)
            $0.top.equalTo(captchaTextField.snp.bottom).offset(30)
        }
    }

    override func setupRx() {
        nextBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.nextHandle()
            }.disposed(by: rx.disposeBag)

        captchaTextField.rx
            .text
            .orEmpty
            .map { $0.trimmed.isNotEmpty && $0.trimmed.count == 6 }
            .bind(to: nextBtn.rx.isEnableAlpha)
            .disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(.UIApplicationWillEnterForeground)
            .subscribeNext { [weak self] noti in
                guard let `self` = self,
                    let pasteString = UIPasteboard.general.string,
                    pasteString.count == 6,
                    let _ = Int(pasteString) else { return }

                self.captchaTextField.text = pasteString
                self.captchaTextField.rx.value.onNext(pasteString)

                HUD.showText("检测到剪贴板验证码，正在登录...",
                             delay: 0.5) { [weak self] in
                    self?.nextHandle()
                }
            }.disposed(by: rx.disposeBag)
    }

    func nextHandle() {
        view.endEditing(true)

        guard let captcha = captchaTextField.text?.trimmed,
            captcha.isNotEmpty,
            captcha.count == 6,
            let _ = Int(captcha) else {
            HUD.showText("请正确验证码", delay: 1.5)
            return
        }

        HUD.show()
        guard let once = AccountModel.getOnce() else {
            HUD.showText("无法获取 once，请尝试重新登录")
            return
        }
        twoStepVerification(code: captcha, once: once, success: { [weak self] in
            NotificationCenter.default.post(.init(name: Notification.Name.V2.LoginSuccessName))
            self?.dismiss()
            HUD.dismiss()
            HUD.showText("登录成功")
        }) { error in
            HUD.dismiss()
            HUD.showText(error)
            self.captchaTextField.becomeFirstResponder()
        }
    }
}

extension TwoStepVerificationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        nextHandle()
        return true
    }
}

