#include <cuda_runtime.h>
#include <iostream>

// Vertex data (position and color)
__constant__ float vertexData[] = {
    0.0f,  1.0f, 0.0f, 1.0f,  1.0f, 0.0f, 0.0f, 1.0f,
   -1.0f, -1.0f, 0.0f, 1.0f,  0.0f, 1.0f, 0.0f, 1.0f,
    1.0f, -1.0f, 0.0f, 1.0f,  0.0f, 0.0f, 1.0f, 1.0f
};

// Check if a point is inside a triangle
__device__ bool isInsideTriangle(float px, float py, float* v0, float* v1, float* v2) {
    auto edgeFunction = [](float* a, float* b, float px, float py) {
        return (px - a[0]) * (b[1] - a[1]) - (py - a[1]) * (b[0] - a[0]);
    };
    float w0 = edgeFunction(v1, v2, px, py);
    float w1 = edgeFunction(v2, v0, px, py);
    float w2 = edgeFunction(v0, v1, px, py);
    return (w0 >= 0 && w1 >= 0 && w2 >= 0);
}

// CUDA kernel for rendering
__global__ void renderTriangle(float* frameBuffer, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;

    float px = (x / (float)width) * 2.0f - 1.0f;
    float py = (y / (float)height) * 2.0f - 1.0f;

    float v0[2] = {vertexData[0], vertexData[1]};
    float v1[2] = {vertexData[8], vertexData[9]};
    float v2[2] = {vertexData[16], vertexData[17]};

    if (isInsideTriangle(px, py, v0, v1, v2)) {
        int idx = (y * width + x) * 4; 
        frameBuffer[idx] = 1.0f;     
        frameBuffer[idx + 1] = 0.0f; 
        frameBuffer[idx + 2] = 0.0f; 
        frameBuffer[idx + 3] = 1.0f; 
    }
}

extern "C" void generateTriangle(float* frameBuffer, int width, int height) {
    float* d_frameBuffer;
    const size_t frameBufferSize = width * height * 4 * sizeof(float);

    cudaMalloc(&d_frameBuffer, frameBufferSize);
    cudaMemset(d_frameBuffer, 0, frameBufferSize);

    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);
    renderTriangle<<<gridSize, blockSize>>>(d_frameBuffer, width, height);
    cudaMemcpy(frameBuffer, d_frameBuffer, frameBufferSize, cudaMemcpyDeviceToHost);

    cudaFree(d_frameBuffer);
}

