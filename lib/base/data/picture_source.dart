import 'package:meta/meta.dart';

/// Sealed class wrapping picture sources
@sealed
class PictureSource {
  const PictureSource();
}

/// Describes picture from assets
class AssetPictureSource extends PictureSource {
  final String assetName;

  const AssetPictureSource(this.assetName);
}

/// Describes picture from the network
class NetworkPictureSource extends PictureSource {
  final String? pictureURL;

  const NetworkPictureSource(this.pictureURL);
}

/// Describes placeholder image when. Used when no other variants specified.
class PlaceholderPictureSource extends PictureSource {
  const PlaceholderPictureSource();
}
