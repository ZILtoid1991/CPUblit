module CPUblit.drawing.common;

version(unittest) {
    import std.stdio;
    public import CPUblit.composing.common : fillWithSingleValue;
    void printMatrix(T)(T[] matrix, size_t width) {
        const size_t height = matrix.length / width;
        for (int y ; y < height ; y++) {
            for (int x ; x < width ; x++) {
                write(matrix[x + y * width]);
            }
            writeln();
        }
    }
}