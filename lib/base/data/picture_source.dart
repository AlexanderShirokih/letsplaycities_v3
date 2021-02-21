import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Sealed class wrapping picture sources
@sealed
class PictureSource {
  const PictureSource();
}

/// Describes picture from assets
class AssetPictureSource extends PictureSource with EquatableMixin {
  final String assetName;

  const AssetPictureSource(this.assetName);

  @override
  List<Object?> get props => [assetName];
}

/// Describes picture from the network
class NetworkPictureSource extends PictureSource with EquatableMixin {
  final String? pictureURL;

  const NetworkPictureSource(this.pictureURL);

  @override
  List<Object?> get props => [pictureURL];
}

/// Describes placeholder image. Used when no other variants specified.
class PlaceholderPictureSource extends PictureSource {
  const PlaceholderPictureSource();
}
