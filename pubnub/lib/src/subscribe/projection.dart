/// Projection names that refer to the base projection, compared lower case.
const _baseProjections = {'default', '__default__'};

/// Normalizes a user provided DataSync [projection] name.
///
/// Returns the trimmed name, or `null` when the base projection is requested.
///
/// @nodoc
String? normalizeProjection(String? projection) {
  if (projection == null) return null;

  var trimmed = projection.trim();
  if (trimmed.isEmpty || _baseProjections.contains(trimmed.toLowerCase())) {
    return null;
  }

  return trimmed;
}

/// Name of the data channel on which [projection] of the DataSync object [id]
/// is observed.
///
/// [projection] has to be normalized with [normalizeProjection]. [id] is used
/// verbatim.
///
/// @nodoc
String projectionChannel(String id, String? projection) =>
    projection == null ? id : '__${projection}__$id';
