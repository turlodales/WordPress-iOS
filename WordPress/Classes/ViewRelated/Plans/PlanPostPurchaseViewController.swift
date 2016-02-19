import UIKit
import WordPressShared

class PlanPostPurchaseViewController: UIViewController {

    private let pageControlHeight: CGFloat = 59
    private let contentTopInset: CGFloat = 25
    private var headingParallaxMaxTranslation: CGFloat = 200
    private var descriptionParallaxMaxTranslation: CGFloat = 100
    
    private weak var pageControl: UIPageControl!
    private weak var scrollView: UIScrollView!
    
    var pageTypes: [PlanPostPurchasePageType]!
    var pages = [PlanPostPurchasePageViewController]() {
        didSet {
            pageControl.numberOfPages = pages.count
        }
    }
    
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: "closeTapped")
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")
        
        return button
    }()
    
    init(plan: Plan) {
        pageTypes = PlanPostPurchasePageType.pageTypesForPlan(plan)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = WPStyleGuide.wordPressBlue()
        edgesForExtendedLayout = .All
        extendedLayoutIncludesOpaqueBars = true

        navigationItem.leftBarButtonItem = cancelXButton

        addPageControl()
        addScrollView()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // If the view is changing size (e.g. on rotation, or multitasking), scroll to the correct page boundary based on the new size
        coordinator.animateAlongsideTransition({ context in
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.currentScrollViewPage()) * size.width, y: 0), animated: true)
            }, completion: nil)
    }
    
    private func addPageControl() {
        let pageControl = UIPageControl()
        view.addSubview(pageControl)
        
        pageControl.tintColor = UIColor.whiteColor()
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        pageControl.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        pageControl.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        pageControl.heightAnchor.constraintEqualToConstant(pageControlHeight).active = true
        
        self.pageControl = pageControl
    }
    
    private func addScrollView() {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.backgroundColor = WPStyleGuide.wordPressBlue()
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(scrollView)
        
        let container = UIStackView()
        container.axis = .Horizontal
        scrollView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.leadingAnchor.constraintEqualToAnchor(scrollView.leadingAnchor).active = true
        container.trailingAnchor.constraintEqualToAnchor(scrollView.trailingAnchor).active = true
        container.bottomAnchor.constraintEqualToAnchor(scrollView.bottomAnchor).active = true
        container.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: contentTopInset).active = true
        
        for pageType in pageTypes {
            let page = PlanPostPurchasePageViewController.controller()
            addChildViewController(page)
            
            page.view.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(page.view)

            page.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
            page.view.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: contentTopInset).active = true
            page.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
            
            page.didMoveToParentViewController(self)
            
            page.pageType = pageType
            
            pages.append(page)
        }
        
        container.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: CGFloat(pages.count))
        
        self.scrollView = scrollView
    }
    
    @IBAction func pageControlChanged() {
    }
    
    func closeTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension PlanPostPurchaseViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPageFraction = (centerX / pageWidth)
        
        for (index, page) in pages.enumerate() {
            let pageCenter = CGFloat(index) + 0.5
            let offset = currentPageFraction - pageCenter
            
            page.headingLabel.transform = CGAffineTransformMakeTranslation(offset * -headingParallaxMaxTranslation, 0)
            page.descriptionLabel.transform = CGAffineTransformMakeTranslation(offset * -descriptionParallaxMaxTranslation, 0)
        }
    }
    
    private func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = Int(floor(centerX / pageWidth))
        
        // Keep it within bounds
        return currentPage.clamp(min: 0, max: pages.count - 1)
    }
}

class PlanPostPurchasePageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    var pageType: PlanPostPurchasePageType? = nil {
        didSet {
            populateViews()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.backgroundColor = WPStyleGuide.wordPressBlue()
        actionButton.tintColor = WPStyleGuide.wordPressBlue()
        
        view.shouldGroupAccessibilityChildren = true
    }
    
    class func controller() -> PlanPostPurchasePageViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanPostPurchasePageViewController
        
        return controller
    }
    
    func setDescriptionText(text: String) {
        let lineHeight: CGFloat = 21
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.alignment = .Center
        
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: descriptionLabel.font])
        descriptionLabel.attributedText = attributedText
    }
    
    func populateViews() {
        guard let pageType = pageType else { return }
        
        switch pageType {
        case .PurchaseComplete:
            headingLabel.text = NSLocalizedString("It’s all yours! Way to go!", comment: "Heading displayed after successful purchase of a plan")
            setDescriptionText(NSLocalizedString("Your site is doing somersaults in excitement! Now explore your site’s new features and choose where you’d like to begin.", comment: "Subtitle displayed after successful purchase of a plan"))
            actionButton.hidden = true
        case .Customize:
            imageView.image = UIImage(named: "plans-post-purchase-customize")
            headingLabel.text = NSLocalizedString("Customize Fonts & Colors", comment: "Heading for customization feature, displayed after plan purchase")
            setDescriptionText(NSLocalizedString("You now have access to custom fonts, custom colors, and custom CSS editing capabilities.", comment: "Descriptive text for customization feature, displayed after plan purchase"))
            actionButton.setTitle(NSLocalizedString("Customize My Site", comment: "Title of button displayed after plan purchase, prompting user to start customizing their site"), forState: .Normal)
        case .VideoPress:
            imageView.image = UIImage(named: "plans-post-purchase-video")
            headingLabel.text = NSLocalizedString("Bring posts to life with video", comment: "Heading for video upload feature, displayed after plan purchase")
            setDescriptionText(NSLocalizedString("You can upload and host videos on your site with VideoPress and your expanded media storage.", comment: "Descriptive text for video upload feature, displayed after plan purchase"))
            actionButton.setTitle(NSLocalizedString("Start New Post", comment: "Title of button displayed after plan purchase, prompting user to start a new post"), forState: .Normal)
        case .Themes:
            imageView.image = UIImage(named: "plans-post-purchase-themes")
            headingLabel.text = NSLocalizedString("Find a perfect, Premium theme", comment: "Title promoting premium themes, displayed after business plan purchase")
            setDescriptionText(NSLocalizedString("You now have unlimited access to Premium themes. Preview any theme on your site to get started.", comment: "Descriptive text promoting premium themes, displayed after business plan purchase"))
            actionButton.setTitle(NSLocalizedString("Browse Themes", comment: "Title of button displayed after business plan purchase"), forState: .Normal)
        }
    }
    
    @IBAction private func actionButtonTapped() {
        guard let pageType = pageType else { return }
        
        // TODO (@frosty, 2016-02-19) These navigation implementations are currently using the primary blog as
        // a temporary placeholder. Once we integrate payments through StoreKit, we should keep a record of the blog
        // that is linked to the current in-flight purchase. That blog can then be handed to this VC when it's presented.
        switch pageType {
        case .Customize:
            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            WPTabBarController.sharedInstance().switchMySitesTabToCustomizeViewForBlog(service.primaryBlog())
            
            WPTabBarController.sharedInstance().dismissViewControllerAnimated(true, completion: nil)
        case .VideoPress:
            WPTabBarController.sharedInstance().dismissViewControllerAnimated(true) {
                WPTabBarController.sharedInstance().showPostTab()
            }
        case .Themes:
            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            WPTabBarController.sharedInstance().switchMySitesTabToThemesViewForBlog(service.primaryBlog())
            
            WPTabBarController.sharedInstance().dismissViewControllerAnimated(true, completion: nil)
        default: break
        }
    }
}

enum PlanPostPurchasePageType: Int {
    case PurchaseComplete
    case Customize
    case VideoPress
    case Themes
    
    static func pageTypesForPlan(plan: Plan) -> [PlanPostPurchasePageType] {
        switch plan {
        case .Premium: return [.PurchaseComplete, .Customize, .VideoPress]
        case .Business: return [.PurchaseComplete, .Customize, .VideoPress, .Themes]
        default: return []
        }
    }
}
