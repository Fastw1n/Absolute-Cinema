import Observation
import UIKit

@MainActor
@Observable
final class MoviePosterViewModel {
    private(set) var image: UIImage?

    func load(name: String?, pixelSize: CGFloat) async {
        image = nil
        guard let name, let original = UIImage(named: name) else { return }
        // UIKit подготавливает уменьшенное изображение в фоне
        let thumbnail = await original.byPreparingThumbnail(
            ofSize: CGSize(width: pixelSize, height: pixelSize)
        )
        guard !Task.isCancelled else { return }
        image = thumbnail
    }
}
