List<E> copy1D<E>(List<E> list) =>
    [...list];

List<List<E>> copy2D<E>(List<List<E>> list) =>
    [for (final sublist in list) copy1D(sublist)];
