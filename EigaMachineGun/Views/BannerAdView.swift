import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
    let adUnitID: String

    init(adUnitID: String = "ca-app-pub-9404799280370656/9432599084") {
        self.adUnitID = adUnitID
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
            BannerViewContainer(adUnitID: adUnitID, adSize: adSize)
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 64)
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.findRootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adSize = adSize
        uiView.rootViewController = Self.findRootViewController()
    }

    static func findRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows.first(where: \.isKeyWindow)?
                .rootViewController
        }
        return scene.windows.first(where: \.isKeyWindow)?.rootViewController
    }
}
