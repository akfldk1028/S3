import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_item.freezed.dart';
part 'job_item.g.dart';

@freezed
abstract class JobItem with _$JobItem {
  const factory JobItem({
    required int idx,
    @JsonKey(name: 'result_url') required String resultUrl,
    @JsonKey(name: 'preview_url') required String previewUrl,
  }) = _JobItem;

  factory JobItem.fromJson(Map<String, dynamic> json) =>
      _$JobItemFromJson(json);
}
