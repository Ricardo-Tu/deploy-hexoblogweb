---
title: Orange AIpro Color triangle帧率测试
sticky: false
comments: true
toc: true
toc_number: true
mathjax: false
highlight_shrink: false
aside: true
copyright: false
date: 2024-07-13 12:00:00
updated:
tags: opengl
categories:
keywords: opengl
description:
cover: 6.png
top_img: /media/16.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

## OpenGL概述
OpenGL ES是KHRNOS Group推出的嵌入式加速3D图像标准，它是嵌入式平台上的专业图形程序接口，它是OpenGL的一个子集，旨在提供高效、轻量级的图形渲染功能。现推出的最新版本是OpenGL ES 3.2。OpenGL和OpenCV OpenCL不同，OpenCV主要用于计算机视觉和图像处理。它提供了一系列算法和函数，用于图像处理、对象检测、机器学习,而OpenGL专注于图形渲染，帮助开发者绘制复杂的2D和3D图形，主要应用于视频游戏、虚拟现实，OpenCL则是一个并行计算框架，主要用于编写并行程序。

## 本文目的
我们这里在Orange AIpro上写了一个color triangle程序，color triangle程序在图形学的地位类似于编程语言学习的Hello World了，可以说人尽皆知了。这边文章介绍了在Orang AIpro上开发运行OpenGL color triangle 并查看帧率

本文使用的窗口管理用SDL2开发，SDL2是一个非常底层的跨平台的多媒体库，主要用于开发2D游戏和多媒体应用程序。提供能了图形、音频、输入输出设备、窗口管理等，功能非常丰富。

## 开发环境
安装部署OpenGL开发环境
```bash
sudo apt install libgles2-mesa libgles2-mesa-dev -y
sudo apt install libsdl2-2.0-0 libsdl2-dev
```

## 源码
### 项目文件结构
项目主要开发语言是c语言，vertex shader 和 fragmeng shader用glsl语言编写，项目的代码在main.cpp中，utils.cpp和utils.cpp中存放了一个工具函数，从文件中读取shader源码编译，编译工具用cmake，compile.sh中存放着重编译运行的shell命令。
```bash
.
├── CMakeLists.txt
├── colortriangle
│   └── utils.hpp
├── compile.sh
├── shader
│   ├── colortriangle.frag
│   └── colortriangle.vert
└── src
    ├── main.cpp
    └── utils.cpp
```

## 窗口循环

主要代码都存放在main.cpp中,对应的文件路径是./src/main.cpp

main.cpp代码如下

```cpp
#define GL_GLEXT_PROTOTYPES
#include <iostream>
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <GLES3/gl32.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <vector>
#include <chrono>
#include <sys/time.h>
 
#include "../colortriangle/utils.hpp"
 
#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 600
 
uint32_t gWinWidth = 800;
uint32_t gWinHeight = 600;
 
struct Vertex
{
    glm::vec3 position;
    glm::vec4 color;
};
 
struct alignas(16) MVP
{
    glm::mat4 model;
    glm::mat4 view;
    glm::mat4 project;
};
 
MVP mvp = {};
 
std::vector<Vertex> basevertex = {
    {{200, 200, 0}, {1, 0, 0, 1}},
    {{600, 200, 0}, {0, 1, 0, 1}},
    {{600, 400, 0}, {0, 0, 1, 1}},
    {{200, 200, 0}, {0, 1, 0, 1}},
    {{200, 400, 0}, {0, 0, 1, 1}},
    {{600, 400, 0}, {1, 1, 1, 1}}};
 
std::vector<Vertex> vertex = {
    {{-10, -10, 0}, {1, 0, 0, 1}},
    {{10, -10, 0}, {0, 1, 0, 1}},
    {{10, 10, 0}, {0, 0, 1, 1}},
    {{-10, -10, 0}, {1, 0, 0, 1}},
    {{-10, 10, 0}, {0, 1, 0, 1}},
    {{10, 10, 0}, {0, 0, 1, 1}}};
 
GLuint indics[] = {0, 1, 2, 0, 4, 5};
 
void UpdateUniformBuffer();
 
int main(int argc, char *argv[])
{
    bool isquit = false;
    SDL_Init(SDL_INIT_EVERYTHING);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
 
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
 
    SDL_Window *window = SDL_CreateWindow("color_triangle",
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          WINDOW_WIDTH, WINDOW_HEIGHT,
                                          SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_OPENGL);
 
    SDL_GLContext context = SDL_GL_CreateContext(window);
 
    GLuint vs, fs, program;
 
    vs = glCreateShader(GL_VERTEX_SHADER);
    fs = glCreateShader(GL_FRAGMENT_SHADER);
 
    std::string vertexShader = readfile("./shader/colortriangle.vert");
    int length = vertexShader.length();
    const GLchar *ptr = vertexShader.c_str();
    glShaderSource(vs, 1, (const GLchar **)&ptr, nullptr);
    glCompileShader(vs);
 
    GLint status;
    glGetShaderiv(vs, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
    {
        throw std::runtime_error("vertex shader compilation failed");
        return 1;
    }
 
    std::string fragmentShader = readfile("./shader/colortriangle.frag");
    length = fragmentShader.length();
    ptr = fragmentShader.c_str();
    glShaderSource(fs, 1, (const GLchar **)&ptr, nullptr);
    glCompileShader(fs);
 
    glGetShaderiv(fs, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
    {
        throw std::runtime_error("fragment shader compilation failed");
        return 1;
    }
 
    program = glCreateProgram();
    UpdateUniformBuffer();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
 
    glBindAttribLocation(program, 0, "position");
    glBindAttribLocation(program, 1, "color");
    glLinkProgram(program);
 
    glUseProgram(program);
 
    glEnable(GL_DEPTH_TEST);
    glClearColor(0, 0.0, 0.0, 0.0);
    glViewport(0, 0, gWinWidth, gWinHeight);
 
    GLuint vao, vbo, ebo, uboBlock;
 
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);
    glGenBuffers(1, &ebo);
 
    glGenBuffers(1, &uboBlock);
    glBindBuffer(GL_UNIFORM_BUFFER, uboBlock);
    glBufferData(GL_UNIFORM_BUFFER, sizeof(MVP), NULL, GL_STATIC_DRAW);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    const auto vpIndex = glGetUniformBlockIndex(program, "ubo");
    glUniformBlockBinding(program, vpIndex, 0);   
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, uboBlock);
 
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
 
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
 
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)(sizeof(vertex[0].position)));
 
    glBufferData(GL_ARRAY_BUFFER, vertex.size() * sizeof(Vertex), vertex.data(), GL_DYNAMIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indics), indics, GL_STATIC_DRAW);
 
    SDL_Event event;
    struct timeval t1, t2;
    struct timezone tz;
    float deltatime;
    float totaltime = 0.0f;
    uint32_t frames = 0;
    gettimeofday(&t1, &tz);
    while (!isquit)
    {
        gettimeofday(&t2, &tz);
        deltatime = (float)(t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec) * 1e-6);
        t1 = t2;
        while (SDL_PollEvent(&event))
        {
            if (event.type == SDL_QUIT)
                isquit = true;
            if (event.type == SDL_WINDOWEVENT)
            {
                if (event.window.event == SDL_WINDOWEVENT_RESIZED)
                {
                    for (size_t i = 0; i < vertex.size(); i++)
                    {
                        SDL_GetWindowSize(window, (int *)&gWinWidth, (int *)&gWinHeight);
                        vertex[i].position.x = gWinWidth / WINDOW_WIDTH * basevertex[i].position.x;
                        vertex[i].position.y = gWinHeight / WINDOW_HEIGHT * basevertex[i].position.y;
                    }
                }
            }
        }
        UpdateUniformBuffer();
        glBindBuffer(GL_UNIFORM_BUFFER, uboBlock);
        glBufferSubData(GL_UNIFORM_BUFFER, 0, sizeof(glm::mat4), &mvp.model);
        glBufferSubData(GL_UNIFORM_BUFFER, sizeof(glm::mat4), sizeof(glm::mat4), &mvp.view);
        glBufferSubData(GL_UNIFORM_BUFFER, sizeof(glm::mat4) * 2, sizeof(glm::mat4), &mvp.project);
        glBindBuffer(GL_UNIFORM_BUFFER, 0);
 
        glViewport(0, 0, gWinWidth, gWinHeight);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindVertexArray(vao);
        glDrawElements(GL_TRIANGLES, sizeof(indics), GL_UNSIGNED_INT, 0);
        SDL_GL_SwapWindow(window);
        totaltime += deltatime;
        frames++;
        if (totaltime > 2.0f)
        {
            SDL_Log("%4d frames rendered in %1.4f seconds -> FPS=[%3.4f]\n", frames, totaltime, frames / totaltime);
            totaltime = 0.0f;
            frames = 0;
        }
    }
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
    SDL_Quit();
 
    return 0;
}
 
void UpdateUniformBuffer()
{
    static auto startTime = std::chrono::high_resolution_clock::now();
    auto currentTime = std::chrono::high_resolution_clock::now();
    float time = std::chrono::duration<float, std::chrono::seconds::period>(currentTime - startTime).count();
 
    mvp.model = glm::rotate(glm::mat4(1.0f), time * glm::radians(90.0f), glm::vec3(0.0f, 0.0f, 1.0f));
    mvp.view = glm::lookAt(glm::vec3(40.0f, 40.0f, 40.0f), glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 1.0f));
    mvp.project = glm::perspective(glm::radians(45.0f), (float)gWinWidth / (float)gWinHeight, 0.1f, 100.0f);
    // mvp.model[1][1] *= -2;
    // mvp.view[1][1] *= 2;
    mvp.project[1][1] *= 1;
}
```

### SDL WindowsLoop
在main.cpp的main函数中窗口的循环如下：
```C++
while (!isquit)
    {
        gettimeofday(&t2, &tz);
        deltatime = (float)(t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec) * 1e-6);
        t1 = t2;
        while (SDL_PollEvent(&event))
        {
            if (event.type == SDL_QUIT)
                isquit = true;
            if (event.type == SDL_WINDOWEVENT)
            {
                if (event.window.event == SDL_WINDOWEVENT_RESIZED)
                {
                    for (size_t i = 0; i < vertex.size(); i++)
                    {
                        SDL_GetWindowSize(window, (int *)&gWinWidth, (int *)&gWinHeight);
                        vertex[i].position.x = gWinWidth / WINDOW_WIDTH * basevertex[i].position.x;
                        vertex[i].position.y = gWinHeight / WINDOW_HEIGHT * basevertex[i].position.y;
                    }
                }
            }
        }
        UpdateUniformBuffer();
        glBindBuffer(GL_UNIFORM_BUFFER, uboBlock);
        glBufferSubData(GL_UNIFORM_BUFFER, 0, sizeof(glm::mat4), &mvp.model);
        glBufferSubData(GL_UNIFORM_BUFFER, sizeof(glm::mat4), sizeof(glm::mat4), &mvp.view);
        glBufferSubData(GL_UNIFORM_BUFFER, sizeof(glm::mat4) * 2, sizeof(glm::mat4), &mvp.project);
        glBindBuffer(GL_UNIFORM_BUFFER, 0);
 
        glViewport(0, 0, gWinWidth, gWinHeight);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindVertexArray(vao);
        glDrawElements(GL_TRIANGLES, sizeof(indics), GL_UNSIGNED_INT, 0);
        SDL_GL_SwapWindow(window);
        totaltime += deltatime;
        frames++;
        if (totaltime > 2.0f)
        {
            SDL_Log("%4d frames rendered in %1.4f seconds -> FPS=[%3.4f]\n", frames, totaltime, frames / totaltime);
            totaltime = 0.0f;
            frames = 0;
        }
    }
```

这部分代码绘制了两个三角形并在窗口循环中创建一个定时器，每两秒计算帧率并输出帧率，这里我们用的手机录制视频，解释一下为什么用手机录制，如果用的录屏软件或者远程vnc远程工具录制都会导致掉帧严重，所以这里采用手机对着显示屏录制

![](1.png)

创建的为800\*600的窗口，帧率稳定在250帧左右

### Vertex Shader Fragment Shader
vertex Shader代码如下，对应的文件路径是./shader/colortriangle.vert
```c++
#version 450
 
layout(std140, binding = 0) uniform UBO {
    mat4 model;
    mat4 view;
    mat4 project;
}ubo;
 
layout(location = 0) in vec3 position;
layout(location = 1) in vec4 color;
layout(location = 0) out vec4 v_color;
 
void main() {
    v_color = color;
    gl_Position = ubo.project * ubo.view * ubo.model * vec4(position, 1.0);
}
```
fragment Shader代码如下，对应的文件路径是./shader/colortriangle.frag
```c++
#version 450 
layout(location = 0) in vec4 v_color;
layout(location = 0) out vec4 o_color;
 
void main() 
{
    o_color = v_color;
}
```
其中通过model view projectation矩阵来控制两个三角形旋转和观察角度
这部分代码如下:
```c++
void UpdateUniformBuffer()
{
    static auto startTime = std::chrono::high_resolution_clock::now();
    auto currentTime = std::chrono::high_resolution_clock::now();
    float time = std::chrono::duration<float, std::chrono::seconds::period>(currentTime - startTime).count();
 
    mvp.model = glm::rotate(glm::mat4(1.0f), time * glm::radians(90.0f), glm::vec3(0.0f, 0.0f, 1.0f));
    mvp.view = glm::lookAt(glm::vec3(40.0f, 40.0f, 40.0f), glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 1.0f));
    mvp.project = glm::perspective(glm::radians(45.0f), (float)gWinWidth / (float)gWinHeight, 0.1f, 100.0f);
    // mvp.model[1][1] *= -2;
    // mvp.view[1][1] *= 2;
    mvp.project[1][1] *= 1;
}
```
首先定义计算程序经过的时间段，用于更新模型矩阵，动态更新，实现动画效果。
其中glm::rotate()用来旋转矩阵
观察矩阵用来设置相机位置观察点以及上向量
投影矩阵用来定义投影视场角宽高比和远近裁剪面，在代码中我定义的两个直角等腰三角形
位置如下：
```c++
struct Vertex
{
    glm::vec3 position;
    glm::vec4 color;
};
 
std::vector<Vertex> vertex = {
    {{-10, -10, 0}, {1, 0, 0, 1}},
    {{10, -10, 0}, {0, 1, 0, 1}},
    {{10, 10, 0}, {0, 0, 1, 1}},
    {{-10, -10, 0}, {1, 0, 0, 1}},
    {{-10, 10, 0}, {0, 1, 0, 1}},
    {{10, 10, 0}, {0, 0, 1, 1}}};
 
```

![](2.png)

将位置信息颜色信息传入vertex shader,模型、观察、投影矩阵通过uniformbufferobject传入vertexshader

### 读取shader文件代码
这部分代码在utils.cpp中，从文件中读取shader代码，并调用glCompileShader编译，源码对应路径是./src/utils.cpp,头文件是./colortriangle/utils.hpp
utils.cpp如下：
```c++
#include "../colortriangle/utils.hpp"
std::string readfile(const std::string &filepath)
{
    std::ifstream file(filepath);
    if (!file.is_open())
    {
        throw std::runtime_error("read shader failed");
    }
 
    std::stringstream sstr;
    sstr << file.rdbuf();
    std::string ret = sstr.str();
    return ret;
}
```
utils.hpp如下：
```c++
#pragma once
 
#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
 
std::string readfile(const std::string &filepath);
```
### 编译命令
项目根目录CMakeLists.txt
```bash
cmake_minimum_required(VERSION 3.10)
project(colortriangle VERSION 1.0)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)
find_package(OpenGL REQUIRED)
find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})
include_directories(${OPENGL_INCLUDE_DIRS})
file(GLOB SOURCES "./src/*.cpp")
add_executable(colortriangle ${SOURCES})
target_link_libraries(colortriangle ${OPENGL_LIBRARIES} ${SDL2_LIBRARIES})
```
### 编译脚本

在根目录执行./compile.sh即可重编译
根目录compile.sh如下:
```bash
#!/bin/bash
rm -rf build
mkdir build 
cd build 
cmake ..
make -j$(nproc)
cd ..
./build/colortriangle
```
测试在800\*600的窗口帧率大概在250帧左右

![](3.png)

缩小窗口后帧率可以达到2500帧

![](4.png)
![](5.png)

## 程序运行动图
这是用向日葵工具远程，然后再windows主机上用录制工具录制，看以看到帧率还没有60帧
![](6.png)
由于手机录制的2分钟视频文件过大，只能存放于百度网盘，附上网盘链接
```bash
链接：https://pan.baidu.com/s/1jbxyl0npx8GE6xP5aS6avQ?pwd=3w8q
提取码：3w8q
```