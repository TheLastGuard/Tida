/++
    Module for matrix transformation.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.matrix;

///
float[4][4] identity() @safe nothrow pure
{
    return  [
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [0, 0, 0, 1]
            ];
}

///
float[4][4] scaleMat(float x, float y) @safe nothrow pure
{
    float[] v = [x, y, 1.0f, 1.0f];
    float[4][4] mat = identity();

    for (int i = 0; i < 4; ++i)
        for (int j = 0; j + 1 < 4; ++j)
            mat[i][j] *= v[j];

    return mat;
}

///
float[4][4] scale(float[4][4] mat, float x, float y) @safe nothrow pure
{
    return mulmat(mat, scaleMat(x, y));
}

///
float[4][4] translation(float x, float y, float z) @safe nothrow pure
{
    auto mat = identity();

    mat[3][0] = x;
    mat[3][1] = y;
    mat[3][2] = z;

    return mat;
}

///
float[4][4] translate(float[4][4] mat, float x, float y, float z) @safe nothrow pure
{
    return mulmat(mat, translation(x, y, z));
}

///
float[4][4] rotateMat(float angle, float x, float y, float z) @safe nothrow pure
{
    import std.math;

    float[4][4] res = identity();

    const float c = cos(angle);
    const oneMinusC = 1 - c;
    const float s = sin(angle);

    res[0][0] = x * x * oneMinusC + c;
    res[0][1] = x * y * oneMinusC - z * s;
    res[0][2] = x * z * oneMinusC + y * s;
    res[1][0] = y * x * oneMinusC + z * s;
    res[1][1] = y * y * oneMinusC + c;
    res[1][2] = y * z * oneMinusC - x * s;
    res[2][0] = z * x * oneMinusC - y * s;
    res[2][1] = z * y * oneMinusC + x * s;
    res[2][2] = z * z * oneMinusC + c;

    return res;
}

///
float[4][4] rotateMat(float[4][4] mat, float angle, float x, float y, float z) @safe nothrow pure
{
    return mulmat(mat, rotateMat(angle, x, y, z));
}

///
float[4][4] eulerRotateMat(float roll, float pitch, float yaw) @safe nothrow pure
{
    import std.math;

    float[4][4] xres = identity();
    float[4][4] yres = identity();
    float[4][4] zres = identity();

    immutable ct = [cos(roll), cos(pitch), cos(yaw)];
    immutable st = [sin(roll), sin(pitch), sin(yaw)];

    xres[1][1] = ct[0];
    xres[1][2] = -st[0];
    xres[2][1] = st[0];
    xres[2][2] = ct[0];

    yres[0][0] = ct[1];
    yres[0][2] = st[1];
    yres[2][0] = -st[1];
    yres[2][2] = ct[1];

    zres[0][0] = ct[2];
    zres[0][1] = -st[2];
    zres[1][0] = st[2];
    zres[1][1] = ct[2];

    return mulmat(mulmat(xres, yres), zres);
}

///
float[4][4] eulerRotate(float[4][4] mat, float roll, float pitch, float yaw) @safe nothrow pure
{
    return mulmat(mat, eulerRotateMat(roll, pitch, yaw));
}

///
float[4][4] mulmat(float[4][4] a, float[4][4] b) @safe nothrow pure
{
    float[4][4] result = 0.0f;

    for(int i = 0; i < 4; ++i)
    {
        for(int j = 0; j < 4; ++j)
        {
            float sum = 0.0f;
            
            for(int k = 0; k < 4; ++k)
                sum += a[i][k] * b[k][j];

            result[i][j] = sum;
        }
    }

    return result;
}
