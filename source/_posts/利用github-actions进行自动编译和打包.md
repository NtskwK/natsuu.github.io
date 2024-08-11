---
title: （脚本）利用github actions进行自动编译和打包
date: 2024-07-19 13:49:12
update:
tags:
- 实践
- github
categories:
- 实践
keywords:
- github action
- 自动化脚本
top_img: https://s2.loli.net/2024/07/19/Ww5Kf9Mog3RvJml.webp
cover: https://s2.loli.net/2024/07/19/iAwyhmD5JHBUlot.jpg
---
[`GitHub Actions`](https://docs.github.com/zh/actions/learn-github-actions/understanding-github-actions) 是一种持续集成和持续交付 (CI/CD) 平台，可用于自动执行生成、测试和部署管道。 可以创建工作流程来构建和测试存储库的每个拉取请求，或将合并的拉取请求部署到生产环境。

我们可以利用github给予免费帐户 `2000分钟/月` 的[免费额度](https://docs.github.com/zh/billing/managing-billing-for-github-actions/about-billing-for-github-actions)的额度来进行很多工作。

# 创建工作流

GitHub Actions 使用 YAML 语法来定义工作流程。 每个工作流都作为单独的文件存放于 .github/workflows 的目录中。


```bash
repository_dir
├─.github
│  └─workflows
│      └─build.yaml
├─.idea
│  └─...
├─.vscode
│  └─...
├─src
│  └─...
...
```

你可以手动创建这个文件，也可以使用 GitHub 提供的工作流入门模板。

![创建工作流](https://s2.loli.net/2024/07/19/riT5gjmBEhQF4IL.jpg)

# 配置工作流文件

这是一个简单的[工作流示例](https://docs.github.com/zh/actions/learn-github-actions/understanding-github-actions#%E5%88%9B%E5%BB%BA%E7%A4%BA%E4%BE%8B%E5%B7%A5%E4%BD%9C%E6%B5%81%E7%A8%8B)。

```yaml
name: learn-github-actions
run-name: learning GitHub Actions
on: [push]
jobs:
  check-bats-version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g bats
      - run: bats -v
```

## name

工作流的名称。（默认值：工作流的文件名称）

## run-name：

工作流运行时的名称。（默认值：`name`）

## on

触发工作流的触发器。 在这个例子中，工作流将在`推送`事件发生时启动。[可用的触发器](https://docs.github.com/zh/actions/using-workflows/events-that-trigger-workflows)

## jobs

工作流中的作业列表。 在这个例子中，工作流包含一个名为 `check-bats-version` 的作业。

一个工作流中可以包含复数的作业，如果不设置作业间的先后顺序则默认视为并发运行。你可以利用[矩阵](https://docs.github.com/zh/actions/using-jobs/using-a-matrix-for-your-jobs)来同时将程序为数个不同的平台进行编译。（这里有一个cmake执行多平台编译的[示例](https://github.com/Dice-Developer-Team/https://github.com/Dice-Developer-Team/Dice/blob/newdev/.github/workflows/cmake.yml/blob/newdev/.github/workflows/cmake.yml)）

**注意：** 执行并发作业产生的费用是分别计算再进行累加的！

## runs-on

作业运行的平台。 [常用的运行平台](https://docs.github.com/zh/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners#%E7%94%A8%E4%BA%8E%E5%85%AC%E5%85%B1%E5%AD%98%E5%82%A8%E5%BA%93%E7%9A%84-github-%E6%89%98%E7%AE%A1%E7%9A%84%E6%A0%87%E5%87%86%E8%BF%90%E8%A1%8C%E5%99%A8)。

## steps

作业中的步骤列表。steps内编排的步骤主要分为两个类型。

### uses

使用[别人编写好的扩展](https://github.com/marketplace)来执行操作。

如下的示例可以调用[该扩展](https://github.com/marketplace/actions/setup-python)在执行工作流的机器中安装python。

```yaml
steps:
  - name: install python
    uses: actions/setup-python@v5 
    with:
        python-version: 'pypy3.9' 

  - name: ...
    with:
      ...
    ...
```
- name: 步骤名称
- uses: 扩展ID
- with: 扩展需要的参数，通常在扩展的说明页面有对应介绍。

### run

利用[可用的shell](https://docs.github.com/zh/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepsshell)执行自定义的脚本。

```yaml
steps:
  - name: Display the path
    shell: pwsh
    run: echo ${env:PATH}

  - name: ...
    ...

  ...
```

- shell: 执行脚本所使用的shell（windows默认值：`pwsh`，其他平台默认值：`bash`）
- run: 执行的命令内容，一次run步骤可以按顺序执行多条命令。下方示例为使用7z进行解压和压缩。

```yaml
- run: |
    7z x -o"win_64" "bin.zip" 
    7z x -o"win_64/bin" "OTB-9.0.0-Win64.zip"
    7z a -tzip win_64.zip win_64/*
```

# Demo

下面是一个完整的[示例文件](https://github.com/NtskwK/Gaofen-Batch/blob/main/.github/workflows/build_parallel.yaml)，用于[Gaofen-Batch](https://github.com/NtskwK/Gaofen-Batch)的编译和打包。

```yaml
name: Build for Windows x86
on:
  # 允许手动触发 
  workflow_dispatch:
  # 推送到main时主动触发
  push:
    branches:
      - main
jobs:
  download_otb:
    runs-on: windows-latest
    steps:
      - run: mkdir OTB-9.0.0-Win64
    
      # 查询缓存状态
      - name: Get otb cache directory
        id: otb-cache
        shell: pwsh
        run: echo "dir=$(pwd)\OTB-9.0.0-Win64" >> ${env:GITHUB_OUTPUT}
      - name: otb cache
        uses: actions/cache@v3
        with:
          path: ${{ steps.otb-cache.outputs.dir }}
          key: ${{ runner.os }}-otb-${{ hashFiles('**/main.py') }}
          restore-keys: |
            ${{ runner.os }}-otb-            
    
      # 如果缓存不存在则进行下载
      - if: ${{ steps.otb-cache.outputs.cache-hit != 'true'}}
        name: download OTB-9.0.0-Win64.zip
        uses: gamedev-thingy/Download-Extract@done
        with:
          url: https://www.orfeo-toolbox.org/packages/OTB-9.0.0-Win64.zip
          destination: OTB-9.0.0-Win64
          ZIPname: OTB-9.0.0-Win64
     
      # 上传文件
      - run: 7z a -tzip OTB-9.0.0-Win64.zip  OTB-9.0.0-Win64/*
      - name: Upload OTB
        uses: actions/upload-artifact@v4
        with:
          # Artifact name
          name: OTB-9.0.0-Win64
          # A file, directory or wildcard pattern that describes what to upload
          path: "OTB-9.0.0-Win64.zip"

  build_python_app:
    runs-on: windows-latest
    steps:
      # 拉取代码
      - uses: actions/checkout@v4
      - name: Get pip cache dir
        id: pip-cache
        run: echo "dir=$(pip cache dir)" >> ${env:GITHUB_OUTPUT}
     
      # 安装python并检查可用的缓存
      - name: install python
        uses: actions/setup-python@v5
        with:
        python-version: '3.10'
        cache: 'pip' # caching pip dependencies
      - name: pip cache
        uses: actions/cache@v3
        with:
          path: ${{ steps.pip-cache.outputs.dir }}
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-
      
      # 编译主程序
      - name: building
        run: |
           pip install -r requirements.txt
           pip install pyinstaller
           pyinstaller main.py

           cp -r "data" "dist/main" 
           cp -r "dist/main" "."
           ren "main" "bin"

           7z a -tzip bin.zip bin/*

      # 上传文件
      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          # Artifact name
          name: bin
          # A file, directory or wildcard pattern that describes what to upload
          path: "bin.zip"


  build_electron_app:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      
      # 安装nodejs并检查可用的缓存
      - name: Setup Node.js environment
        uses: actions/setup-node@v4
        with:
          # Version Spec of the version to use. Examples: 12.x, 10.15.1, >=10.15.0.
          # node-version: 20.x 
          # File containing the version Spec of the version to use.  Examples: package.json, .nvmrc, .node-version, .tool-versions.
          architecture: package.json
          # Set this option if you want the action to check for the latest available version that satisfies the version spec.
          check-latest: true
          # Used to specify a package manager for caching in the default directory. Supported values: npm, yarn, pnpm.
          cache: npm
          # Used to specify the path to a dependency file: package-lock.json, yarn.lock, etc. Supports wildcards or a list of file names for caching multiple dependencies.
          cache-dependency-path: package-lock.json
      - name: Get npm cache directory
        id: npm-cache-dir
        shell: pwsh
        run: echo "dir=$(npm config get cache)" >> ${env:GITHUB_OUTPUT}
      - name: npm cache
        uses: actions/cache@v3
        id: npm-cache # use this to check for `cache-hit` ==> if: steps.npm-cache.outputs.cache-hit != 'true'
        with:
          path: ${{ steps.npm-cache-dir.outputs.dir }}
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      # 安编译GUI
      - name: building and pack
        run: |
           npm install
           npm run pack
           tree

      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          # Artifact name
          name: electron_app
          # A file, directory or wildcard pattern that describes what to upload
          path: "dist/win-unpacked"

  pack_app:
    # 等待其他作业完成后进行拉取
    needs: [download_otb, build_python_app, build_electron_app]
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          # Name of the artifact to download.
          # If unspecified, all artifacts for the run are downloaded.
          # Optional.
          name: OTB-9.0.0-Win64

          # The repository owner and the repository name joined together by "/".
          # If github-token is specified, this is the repository that artifacts will be downloaded from.
          # Optional. Default is ${{ github.repository }}
          repository: ${{ github.repository }}

      
      - uses: actions/download-artifact@v4
        with:
          # Name of the artifact to download.
          # If unspecified, all artifacts for the run are downloaded.
          # Optional.
          name: bin

      - uses: actions/download-artifact@v4
        with:
          # Name of the artifact to download.
          # If unspecified, all artifacts for the run are downloaded.
          # Optional.
          name: electron_app
          path: win_64
          
      # 将编译好的程序进行打包
      - run: |
          7z x -o"win_64" "bin.zip" 
          7z x -o"win_64/bin" "OTB-9.0.0-Win64.zip"
          dir
          dir "win_64"
          dir "win_64/bin"
          dir "win_64/bin/OTB-9.0.0-Win64"
          7z a -tzip win_64.zip win_64/*


      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          # Artifact name
          name: GFB_2.0_win_64
          # A file, directory or wildcard pattern that describes what to upload
          path: "win_64.zip"
```  
p.s.
- 将可以同步进行的工作拆分到不同的作业中可以提高效率~~是因为我不会写异步脚本~~，还有利于在出错时进行排查。
- 如果目标目录中的文件太多导致Upload操作失败，可以先创建压缩文件再执行该操作。但这会与Upload操作自带的压缩行为构成双重压缩（就像以上Demo中的那样）