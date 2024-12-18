#include <fstream>
#include <iostream>

extern "C" void generateTriangle(float* frameBuffer, int width, int height);

int main() {
    const int width = 800;
    const int height = 600;
    const size_t frameBufferSize = width * height * 4 * sizeof(float);

    float* frameBuffer = new float[width * height * 4];
    generateTriangle(frameBuffer, width, height);

    std::ofstream file("triangle.ppm");
    file << "P3\n" << width << " " << height << "\n255\n";
    for (int i = 0; i < width * height; ++i) {
        int idx = i * 4;
        file << static_cast<int>(frameBuffer[idx] * 255) << " "
             << static_cast<int>(frameBuffer[idx + 1] * 255) << " "
             << static_cast<int>(frameBuffer[idx + 2] * 255) << " ";
        if (i % width == width - 1) file << "\n";
    }
    file.close();

    delete[] frameBuffer;
    return 0;
}

