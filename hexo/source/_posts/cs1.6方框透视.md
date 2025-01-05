---
title: cs1.6方框透视
sticky: false
comments: true
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2024-09-14 12:00:00
updated:
tags: tools
categories:
keywords: tools
description:
cover: 4.png
top_img: /media/15.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---


---
### 概述
这篇wiki介绍了怎么cs1.6的方框透视

---
## 涉及内容
 Cheat Engine的使用
 Visual Studio的使用
 界面用Windows MFC绘制
 方框用sdl2框架绘制
 涉及一些MVP矩阵知识

 ---
## 实现步骤
### 搜索矩阵
1. 搜索mvp矩阵，mvp矩阵在其他文章中介绍，也可自行搜索相关文章附上我学习mvp矩阵的网页链接
[mvp矩阵学习链接](https://www.songho.ca/opengl/index.html)

2. 用狙击枪晃动，然后开镜关镜等操作搜索变动的数值以及用键盘Enter键来射击等枪静止搜索未变动的数值来定位mvp矩阵
3. 根据观察mvp矩阵的特征可以大致观察找到的矩阵是否找对
![](1.png)

### 代码实现
1. 实现原理
![](2.svg)
上图可以看出，我们自身的坐标，也就是输入的顶点坐标，通过公式
$$
	模型矩阵*观察矩阵*投影矩阵*转化到屏幕坐标矩阵*自身坐标=屏幕坐标
$$
计算出自身在屏幕的位置，同理我们用这些矩阵乘上敌人坐标就能计算出敌人在屏幕的位置
2. 代码实现
```c++
 for (uint32_t i = 1; i < players.size(); i++)
 {

     float ndc[3] = { 0 };
     float clipCoords[4] = { 0 };
     float clipCoords_yh = 0, ndc_yh = 0, yh_pos = 0;
     float clipCoords_yl = 0, ndc_yl = 0, yl_pos = 0;
     wi.game_width = 1920;
     wi.game_height = 1080;
     clipCoords[0] = players[i].x * selfMatrix[0][0] + players[i].y * selfMatrix[1][0] + players[i].z * selfMatrix[2][0] + selfMatrix[3][0];
     clipCoords[1] = players[i].x * selfMatrix[0][1] + players[i].y * selfMatrix[1][1] + players[i].z * selfMatrix[2][1] + selfMatrix[3][1];
     clipCoords[2] = players[i].x * selfMatrix[0][2] + players[i].y * selfMatrix[1][2] + players[i].z * selfMatrix[2][2] + selfMatrix[3][2];
     clipCoords[3] = players[i].x * selfMatrix[0][3] + players[i].y * selfMatrix[1][3] + players[i].z * selfMatrix[2][3] + selfMatrix[3][3];
     clipCoords_yh = players[i].x * selfMatrix[0][1] + players[i].y * selfMatrix[1][1] + (players[i].z + 25) * selfMatrix[2][1] + selfMatrix[3][1];
     clipCoords_yl = players[i].x * selfMatrix[0][1] + players[i].y * selfMatrix[1][1] + (players[i].z - 35) * selfMatrix[2][1] + selfMatrix[3][1];
     ndc[0] = clipCoords[0] / clipCoords[3];
     ndc[1] = clipCoords[1] / clipCoords[3];
     ndc[2] = clipCoords[2] / clipCoords[3];
     ndc_yh = clipCoords_yh / clipCoords[3];
     ndc_yl = clipCoords_yl / clipCoords[3];
     if (clipCoords[3] < 0.1f)
         continue;
     // 屏幕坐标系x轴朝右y轴朝下，原点在屏幕左上角
     players[i].x_pos = (wi.win_width / 2 * ndc[0]) + (wi.win_width / 2);    // 
     players[i].y_pos = -(wi.win_height / 2 * ((ndc_yh + ndc_yl) / 2)) + (wi.win_height / 2);
     yh_pos = -(wi.win_height / 2 * ndc_yh) + (ndc_yh + wi.win_height / 2);
     yl_pos = -(wi.win_height / 2 * ndc_yl) + (ndc_yl + wi.win_height / 2);
     players[i].rectangle_height = yl_pos - yh_pos;
     players[i].rectangle_width = players[i].rectangle_height * 0.5f;
 }
```
首先我们计算出敌人位置在屏幕上的坐标，
![](ndc转屏幕.svg)
通过计算出人物方框的上边界yh和下边界yl，然后乘以0.5计算出矩形的宽度，这样得到了矩形的长和宽，还需要的一个坐标就是矩形的左上角位置坐标，我们通过人物坐标减去长宽的一半即可，下面是计算方框位置坐标和绘制方框代码
```c++

    void drawBox(SDL_Renderer* render, TTF_Font* font)
    {
        char bloodStr[5];
        SDL_Color color = { 0 };
        SDL_SetRenderDrawColor(render, 0, 0, 0, 255);
        SDL_RenderClear(render);
        drawWindowBox(render);
        if (players.size() == 0)
            return;
        for (int i = 1; i < players.size(); i++)
        {
            auto player = players[i];
            if (player.team == players[0].team)
            {
                color = { 0, 255, 0, 255 };
                SDL_SetRenderDrawColor(render, 0, 255, 0, 255);
            }
            else if (player.team != players[0].team)
            {
                color = { 255, 0, 0, 255 };
                SDL_SetRenderDrawColor(render, 255, 0, 0, 255);
            }
            if (boxShowFlag == 0 || player.team != players[0].team)
            {
                SDL_Rect rect = { (int32_t)(player.x_pos - player.rectangle_width / 2),
                              (int32_t)(player.y_pos - player.rectangle_height / 2),
                              (int32_t)player.rectangle_width,
                              (int32_t)player.rectangle_height };
                SDL_RenderDrawRect(render, &rect);
                memset(bloodStr, 0x00, 5);
                sprintf_s(bloodStr, "%d", player.blood);
                SDL_Surface* surface = TTF_RenderText_Blended(font, bloodStr, color);
                SDL_Texture* texture = SDL_CreateTextureFromSurface(render, surface);
                SDL_FreeSurface(surface);
                SDL_Rect rectFont = rect;
                rectFont.w = 20;
                rectFont.h = 18;
                rectFont.y -= rectFont.w;
                SDL_RenderCopy(render, texture, NULL, &rectFont);

            }
        }
        if (bone_flag == 1)
        {
            readBonePosition((uint32_t)players.size());
            drawBone(render);
        }
        SDL_RenderPresent(render);
    }
```

### 绘制效果展示
![](4.png)

---
![](5.svg)