// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) {
  return _TaskModel.fromJson(json);
}

/// @nodoc
mixin _$TaskModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description =>
      throw _privateConstructorUsedError; // Mô tả có thể null
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'assignee_id')
  String? get assigneeId => throw _privateConstructorUsedError; // ID của người được giao, có thể null
  String? get assigneeName =>
      throw _privateConstructorUsedError; // Tên người được giao (sẽ được fetch và điền sau)
  String? get assigneeAvatarUrl =>
      throw _privateConstructorUsedError; // Ảnh đại diện người được giao (sẽ được fetch và điền sau)
  String get status =>
      throw _privateConstructorUsedError; // 'todo', 'doing', 'done'
  String get priority =>
      throw _privateConstructorUsedError; // 'low', 'medium', 'high'
  @JsonKey(name: 'due_date')
  DateTime? get dueDate => throw _privateConstructorUsedError; // Ngày hết hạn, có thể null
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskModelCopyWith<TaskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskModelCopyWith<$Res> {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) then) =
      _$TaskModelCopyWithImpl<$Res, TaskModel>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    @JsonKey(name: 'project_id') String projectId,
    @JsonKey(name: 'assignee_id') String? assigneeId,
    String? assigneeName,
    String? assigneeAvatarUrl,
    String status,
    String priority,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$TaskModelCopyWithImpl<$Res, $Val extends TaskModel>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? projectId = null,
    Object? assigneeId = freezed,
    Object? assigneeName = freezed,
    Object? assigneeAvatarUrl = freezed,
    Object? status = null,
    Object? priority = null,
    Object? dueDate = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            assigneeId: freezed == assigneeId
                ? _value.assigneeId
                : assigneeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assigneeName: freezed == assigneeName
                ? _value.assigneeName
                : assigneeName // ignore: cast_nullable_to_non_nullable
                      as String?,
            assigneeAvatarUrl: freezed == assigneeAvatarUrl
                ? _value.assigneeAvatarUrl
                : assigneeAvatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskModelImplCopyWith<$Res>
    implements $TaskModelCopyWith<$Res> {
  factory _$$TaskModelImplCopyWith(
    _$TaskModelImpl value,
    $Res Function(_$TaskModelImpl) then,
  ) = __$$TaskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    @JsonKey(name: 'project_id') String projectId,
    @JsonKey(name: 'assignee_id') String? assigneeId,
    String? assigneeName,
    String? assigneeAvatarUrl,
    String status,
    String priority,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$TaskModelImplCopyWithImpl<$Res>
    extends _$TaskModelCopyWithImpl<$Res, _$TaskModelImpl>
    implements _$$TaskModelImplCopyWith<$Res> {
  __$$TaskModelImplCopyWithImpl(
    _$TaskModelImpl _value,
    $Res Function(_$TaskModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? projectId = null,
    Object? assigneeId = freezed,
    Object? assigneeName = freezed,
    Object? assigneeAvatarUrl = freezed,
    Object? status = null,
    Object? priority = null,
    Object? dueDate = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$TaskModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        assigneeId: freezed == assigneeId
            ? _value.assigneeId
            : assigneeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assigneeName: freezed == assigneeName
            ? _value.assigneeName
            : assigneeName // ignore: cast_nullable_to_non_nullable
                  as String?,
        assigneeAvatarUrl: freezed == assigneeAvatarUrl
            ? _value.assigneeAvatarUrl
            : assigneeAvatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskModelImpl with DiagnosticableTreeMixin implements _TaskModel {
  const _$TaskModelImpl({
    required this.id,
    required this.title,
    this.description,
    @JsonKey(name: 'project_id') required this.projectId,
    @JsonKey(name: 'assignee_id') this.assigneeId,
    this.assigneeName,
    this.assigneeAvatarUrl,
    required this.status,
    required this.priority,
    @JsonKey(name: 'due_date') this.dueDate,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$TaskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  // Mô tả có thể null
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  @JsonKey(name: 'assignee_id')
  final String? assigneeId;
  // ID của người được giao, có thể null
  @override
  final String? assigneeName;
  // Tên người được giao (sẽ được fetch và điền sau)
  @override
  final String? assigneeAvatarUrl;
  // Ảnh đại diện người được giao (sẽ được fetch và điền sau)
  @override
  final String status;
  // 'todo', 'doing', 'done'
  @override
  final String priority;
  // 'low', 'medium', 'high'
  @override
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  // Ngày hết hạn, có thể null
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TaskModel(id: $id, title: $title, description: $description, projectId: $projectId, assigneeId: $assigneeId, assigneeName: $assigneeName, assigneeAvatarUrl: $assigneeAvatarUrl, status: $status, priority: $priority, dueDate: $dueDate, createdAt: $createdAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'TaskModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('projectId', projectId))
      ..add(DiagnosticsProperty('assigneeId', assigneeId))
      ..add(DiagnosticsProperty('assigneeName', assigneeName))
      ..add(DiagnosticsProperty('assigneeAvatarUrl', assigneeAvatarUrl))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('priority', priority))
      ..add(DiagnosticsProperty('dueDate', dueDate))
      ..add(DiagnosticsProperty('createdAt', createdAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.assigneeId, assigneeId) ||
                other.assigneeId == assigneeId) &&
            (identical(other.assigneeName, assigneeName) ||
                other.assigneeName == assigneeName) &&
            (identical(other.assigneeAvatarUrl, assigneeAvatarUrl) ||
                other.assigneeAvatarUrl == assigneeAvatarUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    projectId,
    assigneeId,
    assigneeName,
    assigneeAvatarUrl,
    status,
    priority,
    dueDate,
    createdAt,
  );

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      __$$TaskModelImplCopyWithImpl<_$TaskModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskModelImplToJson(this);
  }
}

abstract class _TaskModel implements TaskModel {
  const factory _TaskModel({
    required final String id,
    required final String title,
    final String? description,
    @JsonKey(name: 'project_id') required final String projectId,
    @JsonKey(name: 'assignee_id') final String? assigneeId,
    final String? assigneeName,
    final String? assigneeAvatarUrl,
    required final String status,
    required final String priority,
    @JsonKey(name: 'due_date') final DateTime? dueDate,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$TaskModelImpl;

  factory _TaskModel.fromJson(Map<String, dynamic> json) =
      _$TaskModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description; // Mô tả có thể null
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  @JsonKey(name: 'assignee_id')
  String? get assigneeId; // ID của người được giao, có thể null
  @override
  String? get assigneeName; // Tên người được giao (sẽ được fetch và điền sau)
  @override
  String? get assigneeAvatarUrl; // Ảnh đại diện người được giao (sẽ được fetch và điền sau)
  @override
  String get status; // 'todo', 'doing', 'done'
  @override
  String get priority; // 'low', 'medium', 'high'
  @override
  @JsonKey(name: 'due_date')
  DateTime? get dueDate; // Ngày hết hạn, có thể null
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
