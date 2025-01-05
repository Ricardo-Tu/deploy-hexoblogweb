---
title: vulkan变换与坐标系（翻译）
sticky: false
comments: false
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2024-08-10 12:00:00
updated:
tags: vulkan 
categories:
keywords: vulkan
description:
cover: 3.png
top_img: /media/8.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

# 概述
在光栅化过程之前，顶点位置和法线向量等几何数据通过Rasterization Pipeline顶点操作和图元操作进行变换
1. 顶点操作包括模型变换、视图变换、投影变换
2. 图元操作包括将点组成的图元、剔除、裁剪、屏幕投影

![](1.svg)

## 模型矩阵
输入没有经过任何的变换顶点数据是物体的局部坐标，经过模型矩阵变换后，将物体从模型空间坐标转化为世界空间的坐标，矩阵中可以包含平移、缩放、旋转等变换

1. 平移矩阵
  $$
    \begin{pmatrix}
    X \\
    Y \\
    Z \\
    1 \\
    \end{pmatrix}
    = 
    \begin{pmatrix}
    1 & 0 & 0 & d_x  \\
    0 & 1 & 0 & d_y  \\
    0 & 0 & 1 & d_z  \\
    0 & 0 & 0 & 1    \\
    \end{pmatrix}
    *
    \begin{pmatrix}
    x_0 \\
    y_0 \\
    z_0 \\
    1   \\
    \end{pmatrix}
  $$

  等号左边表示为顶点的齐次坐标(x,y,z,1)，是将等号右边的4\*4矩阵为平移矩阵，是将(x<sub>0</sub>,y<sub>0</sub>,z<sub>0</sub>,1)进行平移变换，平移(d<sub>x</sub>,d<sub>y</sub>,d<sub>z</sub>,0)

2. 缩放矩阵

  $$
    \begin{pmatrix}
    X \\
    Y \\
    Z \\
    1 \\
    \end{pmatrix}
    = 
    \begin{pmatrix}
     s_x & 0 & 0 & 0  \\
     0 & s_y & 0 & 0  \\
     0 & 0 & s_z & 0  \\
     0 & 0 & 0 & 1    \\
    \end{pmatrix}
    *
    \begin{pmatrix}
     x_0 \\
     y_0 \\
     z_0 \\
     1   \\
    \end{pmatrix}
  $$

  等号左边表示为顶点的齐次坐标(x,y,z,1)，是将等号右边的4\*4矩阵为缩放矩阵，是将(x<sub>0</sub>,y<sub>0</sub>,z<sub>0</sub>,1)进行缩放变换

3. 旋转矩阵
  - 绕x轴旋转α角	

    $$
      \begin{pmatrix}
      x_0 \\
      y_0*cosα-z_0*sinα \\
      y_0*sinα+z_0*cosα \\
      1 \\
      \end{pmatrix}
      = 
      \begin{pmatrix}
       1 & 0 & 0 & 0  \\
       0 & cosα & -sinα & 0  \\
       0 & sinα & cosα & 0  \\
       0 & 0 & 0 & 1    \\
      \end{pmatrix}
      *
      \begin{pmatrix}
       x_0 \\
       y_0 \\
       z_0 \\
       1   \\
      \end{pmatrix}
    $$

    - 绕y轴旋转β角	
        $$
          \left(
          \begin{matrix}
          z_0*sinβ+x_0*cosβ \\
          y_0 \\
          z_0*cosβ-x_0*sinβ \\
          1 \\
          \end{matrix}
          \right)
          = 
          \left(
          \begin{matrix}
           cosβ & 0 & sinβ & 0  \\
           0 & 1 & 0 & 0  \\
           -sinβ & 0 & cosβ & 0  \\
           0 & 0 & 0 & 1    \\
          \end{matrix}
          \right)
          *
          \left(
          \begin{matrix}
           x_0 \\
           y_0 \\
           z_0 \\
           1   \\
          \end{matrix}
          \right)
        $$

    - 绕z轴旋转γ角	
        $$
          \begin{pmatrix}
          x_0*cosγ-y_0*sinγ \\
          x_0*sinγ+y_0*cosγ \\
          z_0 \\
          1 \\
          \end{pmatrix}
          = 
          \begin{pmatrix}
           cosγ & -sinγ & 0 & 0  \\
           sinγ & cosγ & 0 & 0  \\
           0 & 0 & 1 & 0  \\
           0 & 0 & 0 & 1    \\
          \end{pmatrix}
          *
          \begin{pmatrix}
           x_0 \\
           y_0 \\
           z_0 \\
           1   \\
          \end{pmatrix}
        $$

        旋转矩阵公式推导步骤：
        绕z轴旋转y角，z的坐标不变，x、y坐标发生变化

        ![](2.png)
        
        假设原始点位置为：
        $$
        \begin{cases}
         \ x=R*cosθ \\
         \ y=R*sinθ
        \end{cases}
        $$

        将这个点绕z轴旋转γ角，所以z坐标不变，x，y坐标改变，旋转后点坐标为

        $$
        \begin{cases}
         \ X=R*cos(θ+γ) \\
         \ Y=R*sin(θ+γ)
        \end{cases}
        $$
        $$
        \begin{aligned}
        X
        &=R*cos(θ+γ) \\
        &=R*(cosθ*cosγ-sinθ*sinγ) \\
        &=R*cosθcosγ-R*sinθsinγ \\
        &=x*cosγ-y*sinγ
        \end{aligned}
        $$
        $$
        \begin{aligned}
        Y
        &=R*sin(θ+γ) \\
        &=R*(sinθ*cosγ+cosθ*sinγ) \\
        &=R*sinθ*cosγ+R*cosθ*sinγ \\
        &=y*cosγ+x*sinγ
        \end{aligned}
        $$

        旋转后点的坐标为

        $$
        \begin{cases}
         \ X=x*cosγ+y*sinγ \\
         \ Y=y*cosγ+x*sinγ
        \end{cases}
        $$

        将方程组的等效矩阵为：

        $$
          \begin{pmatrix}
          x*cosγ-y*sinγ \\
          x*sinγ+y*cosγ \\
          z \\
          1 \\
          \end{pmatrix}
          = 
          \begin{pmatrix}
           cosγ & -sinγ & 0 & 0  \\
           sinγ & cosγ & 0 & 0  \\
           0 & 0 & 1 & 0  \\
           0 & 0 & 0 & 1    \\
          \end{pmatrix}
          *
          \begin{pmatrix}
           x \\
           y \\
           z \\
           1 \\
          \end{pmatrix}
        $$

## 观察矩阵

确定一个观察位置，然后将模型位置从世界坐标转化到观察位置，这个矩阵确定了相机位置，以及相机的上方向。相机位置很容易理解就是观察者的位置，其他物体的坐标会根据观察者的位置的改变而相应做出改变，相机的上方向即是确定了相机的倾斜角度，类似于屏幕，相机可以是水平可以竖直可以倾斜任意角度，所以需要确定一个相机的上方向，保证观察的角度不会倾斜倒置

## 投影矩阵

  是将3D场景变换为2D场景，以便于在计算机屏幕上显示。投影矩阵就用于此投影变换，首先，它将所有的顶点数据从相对于观察者的坐标转化为裁剪坐标，然后通过除以裁剪坐标的w分量，将这些裁剪坐标转化为ndc坐标(Normalized Device Coordinates)。
  因此，我们必须记住，裁剪（视锥剔除）和NDC变化都集成到了投影矩阵中，在模型矩阵中，定义了视锥体的上下左右边界，所以裁剪剔除和ndc的变换都集成到了投影矩阵中

  ![](3.png)

  在透视投影中，视锥体中的3D坐标被映射到立方体中，这时的坐标为ndc，x、y的坐标范围分别从\[l,r\] \[t,b\]映射到\[-1,1\] \[-1,1\]，在vulkan中观察矩阵为左手系，上面左图坐标系错误，ndc坐标为右手系，上面右边立方体的坐标系错误，图中为左手系
  在vulkan中，观察空间中的3D点被投影到投影平面上，下面显示了观察空间中的点(x<sub>e</sub>,y<sub>e</sub>,z<sub>e</sub>)是如何投影到投影平面上的(x<sub>p</sub>,y<sub>p</sub>,z<sub>p</sub>) 

  ![](4.png)

  左图是视锥体的俯视图，将观察空间中的x坐标x<sub>e</sub>映射到x<sub>p</sub>，通过相似三角形计算：

  $$
    \frac {x_{project}} {x_{eye}} = \frac {n} {z_{eye}}
  $$  

  $$
    x_{project}=\frac {n*x_{eye}} {z_{eye}}
    \tag{1}
  $$

  右图为视锥体的右视图，将观察空间中的y坐标y<sub>e</sub>映射到y<sub>e</sub>，通过相似三角形计算：

  $$
    \frac{y_{project}}{y_{eye}}=\frac{n}{z_{eye}}
  $$

  $$
    y_{project}=\frac{n*y_{eye}}{z_{eye}}
    \tag{2}
  $$

  其中x<sub>p</sub>和y<sub>p</sub>都依赖于z<sub>e</sub>，它们与z<sub>e</sub>成反比，所以这是构造投影矩阵的第一个线索，通过乘以投影矩阵对观察坐标进行变换后，裁剪坐标仍然是一个齐次坐标，它最终通过除以裁剪坐标的w分量来变为ndc

  $$
      \begin{pmatrix}
      x_{clip} \\
      y_{clip} \\
      y_{clip} \\
      w_{clip} \\
      \end{pmatrix}
      = 
      M_{project} * \\
      \begin{pmatrix}
       x_{eye} \\
       y_{eye} \\
       z_{eye} \\
       w_{eye} \\
      \end{pmatrix}
    \tag{3}
  $$

  $$
    \begin{pmatrix}
    x_{ndc} \\
    y_{ndc} \\
    y_{ndc} \\
    \end{pmatrix}
    = 
    M_{project} * \\
    \begin{pmatrix}
     x_{clip}/w_{ndc} \\
     x_{clip}/w_{ndc} \\
     x_{clip}/w_{ndc} \\
    \end{pmatrix}
    \tag{4}
  $$

  因此，我们可以将裁剪坐标的w分量设置为z<sub>e</sub>，这样，模型矩阵的第四行就变成了(0,0,1,0)

  $$ 
    \begin{pmatrix}
    . & . & . & . \\
    . & . & . & . \\
    . & . & .& .  \\
    0 & 0 & 1 & 0 \\
    \end{pmatrix}
    \tag{5}
  $$

  接着，我们将x<sub>p</sub>和y<sub>p</sub>映射到NDC的x<sub>n</sub>和y<sub>n</sub>，具有线性关系；\[l,r\]=>\[-1,1\]和\[t,b\]=>\[-1,1\]

  ![](5.png)

  $$
    x_{ndc} = \frac{1-(-1)}{r-l}*x_{project}+β
    \tag{6}
  $$

  上式满足当x<sub>p</sub>=r时，x<sub>n</sub>=1，所以代入上式可得：

  $$
    1=\frac{2r}{r-l}+β
    \tag{7}
  $$

  移项可得:

  $$
    \begin{aligned}
    β
    &=1-\frac{2r}{r-l} \\
    &=\frac{r-l}{r-l}-\frac{2r}{r-l} \\
    &=\frac{r-l-2r}{r-l} \\
    &=\frac{-r-l}{r-l} \\
    &=-\frac{r+l}{r-l}
    \end{aligned}
    \tag{8}
  $$

  所以将(8)式结论带入(6)式中可得

  $$
    \begin{aligned}
    x_n=\frac{2*x_p}{r-l}-\frac{r+l}{r-l}
    \end{aligned}
    \tag{9}
  $$

  ![](6.png)

  $$
    y_{ndc}=\frac{1-(-1)}{b-t}*y_{project}+β
    \tag{10}
  $$

  上式满足当y<sub>p</sub>=b时，y<sub>n</sub>=1，带入上式可得：

  $$
    1=\frac{2b}{b-t}+β
    \tag{11}
  $$

  移项可得：

  $$
    \begin{aligned}
    β
    &=1-\frac{2b}{b-t} \\
    &=\frac{b-t}{b-t}-\frac{2b}{b-t} \\
    &=\frac{-b-t}{b-t} \\
    &=-\frac{b+t}{b-t}
    \end{aligned}
    \tag{12}
  $$

  将(12)带入(10)中可得：

  $$
    y_{ndc}=\frac{2*x_{project}}{b-t}*y_{project}-\frac{b+t}{b-t}
    \tag{13}
  $$

  然后，我们将(1)带入(9)中可得：

  $$
    \begin{aligned}
    x_{ndc}
    &=\frac{2*x_{project}}{r-l}-\frac{r+l}{r-l} \\
    &=\frac{2*\frac{n*x_{eye}}{z_{eye}}}{r-l}-\frac{r+l}{r-l} \\
    &=\frac{2*n*x_{eye}}{(r-l)*z_{eye}}-\frac{r+l}{r-l} \\
    &=\frac{\frac{2*n}{r-l}*x_{eye}}{z_{eye}}-\frac{r+l}{r-l} \\
    &=\frac{\frac{2*n}{r-l}*x_{eye}}{z_{eye}}-\frac{\frac{r+l}{r-l}*z_{eye}}{z_{eye}} \\
    &=(\frac{2*n}{r-l}*x_{eye}-\frac{r+l}{r-l}*z_{eye})/z_{eye}
    \end{aligned}
    \tag{14}
  $$

  将结果结合(4)中的

  $$
    x_{ndc}=\frac{x_{clip}}{w_{clip}}
    \tag{15}
  $$

  可得

  $$
    x_{clip}=\frac{2*n}{r-l}*x_{eye}-\frac{r+l}{r-l}*z_{eye}
    \tag{16}
  $$

  将(2)带入(13)中可得：

  $$
    \begin{aligned}
    y_{ndc}
    &=\frac{2*y_{project}}{b-t}-\frac{b+t}{b-t} \\
    &=\frac{2*\frac{n*y_{eye}}{z_{eye}}}{b-t}-\frac{b+t}{b-t} \\
    &=\frac{2*n*y_{eye}}{(b-t)*z_{eye}}-\frac{b+t}{b-t} \\
    &=\frac{\frac{2*n}{b-t}*y_{eye}}{z_{eye}}-\frac{b+t}{b-t} \\
    &=\frac{\frac{2*n}{b-t}*y_{eye}}{z_{eye}}-\frac{\frac{b+t}{b-t}*z_{eye}}{z_{eye}} \\
    &=(\frac{2*n}{b-t}*y_{eye}-\frac{b+t}{b-t}*z_{eye})/z_{eye}
    \end{aligned}
  $$

  将结果结合(4)中的

  $$
    y_{ndc}=\frac{y_{clip}}{w_{clip}}
    \tag{17}
  $$

  可得

  $$
    y_{clip}=\frac{2*n}{b-t}*y_{eye}-\frac{b+t}{b-t}*z_{eye}
    \tag{18}
  $$

  根据(16)和(18)可的矩阵的部分：

  $$
    \begin{pmatrix}
    x_{clip} \\
    y_{clip} \\
    z_{clip} \\
    w_{clip} \\
    \end{pmatrix}
    =
    \begin{pmatrix}
    \frac{2*n}{r-l} & 0 & \frac{r+l}{r-l} & 0 \\
    0 & \frac{2*n}{b-t} & \frac{b+t}{b-t} & 0 \\
    . & . & . & .  \\
    0 & 0 & 1 & 0 \\
    \end{pmatrix}
    *
    \begin{pmatrix}
    x_{eye} \\
    y_{eye} \\
    z_{eye} \\
    w_{eye} \\
    \end{pmatrix}
    \tag{19}
  $$

  现在还剩下最后投影矩阵的第三行，由于对投影到ndc坐标的一个点可以对应从观察者坐标到投影点连线的延长线上的任意一点，所以可以知道z<sub>clip</sub>和z<sub>eye</sub>的关系与点x、y坐标无关，所以填充公式(19)中的(3,0)(3,1)位置并设(3,2)(3,3)位置的变量为A和B

  $$
    \begin{pmatrix}
    x_{clip} \\
    y_{clip} \\
    z_{clip} \\
    w_{clip} \\
    \end{pmatrix}
    =
    \begin{pmatrix}
    \frac{2*n}{r-l} & 0 & \frac{r+l}{r-l} & 0 \\
    0 & \frac{2*n}{b-t} & \frac{b+t}{b-t} & 0 \\
    0 & 0 & A & B  \\
    0 & 0 & 1 & 0 \\
    \end{pmatrix}
    *
    \begin{pmatrix}
    x_{eye} \\
    y_{eye} \\
    z_{eye} \\
    w_{eye} \\
    \end{pmatrix}
    \tag{19}
  $$

  结合(4)中的

  $$
    z_{ndc}=\frac{z_{eye}}{w_{clip}}=\frac{A*z_{eye}+B*w_{eye}}{z_{eye}}
    \tag{20}
  $$

  在观察空间中，w<sub>eye</sub>=1，因此方程变为：

  $$
    z_{ndc}=\frac{A*z_{eye}+B}{Z_{eye}}
    \tag{21}
  $$

  我们带入特殊值，将(n,-1)和(f,1)带入(z<sub>eye</sub>,z<sub>ndc</sub>)中

  $$
    \begin{cases}
     \ -1=\frac{A*n+B}{n} \\
     \ 1=\frac{A*f+B}{f}
    \end{cases}
    \tag{22}
  $$

  化简得：

  $$
    \begin{cases}
     \ -n=A*n+B \\
     \ f=A*f+B
    \end{cases}
    \tag{23}
  $$

  对于方程式(23)其中的f和n时常数，所以其中的变量为AB，解方程组可得：

  $$
    \begin{cases}
     \ A= \frac{f+n}{f-n}\\
     \ B= \frac{-2*f*n}{f-n}
    \end{cases}
    \tag{23}
  $$

  将A,B带入(19)中可得投影矩阵为:

  $$
    \begin{pmatrix}
    \frac{2*n}{r-l} & 0 & \frac{r+l}{r-l} & 0 \\
    0 & \frac{2*n}{b-t} & \frac{b+t}{b-t} & 0 \\
    0 & 0 & \frac{f+n}{f-n} & \frac{-2*f*n}{f-n}  \\
    0 & 0 & 1 & 0 \\
    \end{pmatrix}
  $$

  这个投影矩阵适用于任意形状的截头视锥体投影在原点在投影矩形的任意位置，当原点在投影平面的任意位置时,类似于枪战游戏中枪口指针肯定会在屏幕的中心，即r=-l b=-t，则投影矩阵可以简化为：

  $$
    \begin{pmatrix}
    \frac{n}{r} & 0 & 0 & 0 \\
    0 & \frac{n}{b} & 0 & 0 \\
    0 & 0 & \frac{f+n}{f-n} & \frac{-2*f*n}{f-n}  \\
    0 & 0 & 1 & 0 \\
    \end{pmatrix}
  $$

  其中r就为屏幕的宽度一半，b为屏幕高度的一半，即：

  $$
    \begin{cases}
     \ r= \frac{width}{2}\\
     \ b= \frac{height}{2}
    \end{cases}
  $$

## 视口变化
  将ndc转化为屏幕上显示的坐标，以便画面在屏幕上显示，此时窗口坐标仍保留着z坐标，z坐标的作用是在fragment shader中进行深度测试

  ![](7.png)

  上面左图为opengl，是左手系，在vulkan中ndc坐标为右手系，左图的y轴正方向朝下为vulkan坐标系，所以坐标点应该变化，在vulkan中输入数据有窗口的高度宽度以及深度范围，深度范围默认是(0.0f,1.0f)
    当坐标由ndc(x<sub>ndc</sub>,y<sub>ndc</sub>,z<sub>ndc</sub>)至窗口坐标(x<sub>windows</sub>,y<sub>windows</sub>,z<sub>windows</sub>)

  $$
    \begin{aligned}
    x_{windows}
    &=\frac{x+w-x}{1-(-1)}*x_{ndc}+α  \\
    &=\frac{w}{2}*x_{ndc}+α
    \end{aligned}
    \tag{24}
  $$

  由上图可知，取特殊值，当x<sub>ndc</sub>=-1时，x<sub>windows</sub>=x，将值带入(24)式得

  $$
    x=\frac{w}{2}*-1+α
    \tag{25}
  $$

  化简(25)可得

  $$
    α=x+\frac{w}{2}
    \tag{26}
  $$

  将(26)带入(24)式可得

  $$
    x_{windows}=\frac{w}{2}*x_{ndc}+(x+\frac{w}{2})
    \tag{27}
  $$

  同理对于y方向来说

  $$
    \begin{aligned}
    y_{windows}
    &=\frac{y-(y+h)}{1-(-1)}*y_{ndc}+β \\
    &=\frac{h}{2}*y_{ndc}+β
    \end{aligned}
    \tag{28}
  $$

  取特殊值，当y<sub>ndc</sub>=1时，y<sub>windows</sub>=y，将值带入(28)式得

  $$
    y=\frac{h}{2}+β
    \tag{29}
  $$

  化简(29)可得

  $$
    β=y-\frac{h}{2}
    \tag{30}
  $$

  将(30)带入(28)可得

  $$
    y_{windows}=\frac{h}{2}*y_{ndc}+(y-\frac{h}{2})
    \tag{31}
  $$

  同理对于z方向

  $$
    \begin{aligned}
    z_{windows}
    &=\frac{F-N}{1-(-1)}*z_{ndc}+γ \\
    &=\frac{F-N}{2}*z_{ndc}+γ
    \end{aligned}
    \tag{32}
  $$

  取特殊值，当z<sub>ndc</sub>=1时，z<sub>windows</sub>=F，将值带入(28)式得

  $$
    F=\frac{F-N}{2}+γ
    \tag{33}
  $$

  化简(33)可得

  $$
    \begin{aligned}
    γ
    &=F-\frac{F-N}{2} \\
    &=\frac{F+N}{2}
    \end{aligned}
    \tag{34}
  $$

  将(34)带入(32)中可得

  $$
    z_{windows}=\frac{F-N}{2}*z_{ndc}+\frac{F+N}{2}
    \tag{35}
  $$

  结合(27)(31)(35)式可得

  $$
    \begin{cases}
     \ x_{windows}=\frac{w}{2}*x_{ndc}+(x+\frac{w}{2}) \\
     \ y_{windows}=\frac{h}{2}*y_{ndc}+(y-\frac{h}{2}) \\
     \ z_{windows}=\frac{F-N}{2}*z_{ndc}+\frac{F+N}{2}
    \end{cases}
    \tag{36}
  $$

  这个方程组得等效矩阵为

  $$
    \begin{pmatrix}
    x_{widnows} \\
    y_{widnows} \\
    z_{widnows} \\
    1 \\
    \end{pmatrix}
    =
    \begin{pmatrix}
    \frac{w}{2} & 0 & 0 & x+\frac{w}{2} \\
    0 & \frac{h}{2} & 0 & y-\frac{h}{2} \\
    0 & 0 & \frac{F-N}{2} & \frac{F+N}{2}  \\
    0 & 0 & 0 & 1 \\
    \end{pmatrix}
    *
    \begin{pmatrix}
    x_{eye} \\
    y_{eye} \\
    z_{eye} \\
    w_{eye} \\
    \end{pmatrix}
    \tag{37}
  $$

---

## 原文链接
[原文链接](https://www.songho.ca/opengl/gl_transform.html)
