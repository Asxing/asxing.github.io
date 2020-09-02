---
title: Common-VScode（二）
author: HoldDie
tags: [Tools,效率,VScode]
top: false
date: 2019-01-28 19:43:41
categories: Tools 
---



> **花开在天边，而我需要走过一路的荆棘。 ——折焰**

### VSCode

- 基础功能

  - 转到定义：f12
  - 查看引用：shift+f12
  - 跳转到文件的符号：command + f12
  - 终端：option+f12
  - 跳转到工作区的符号：caps+t
  - 拖动的时候，按住Option键时就可以复制这块代码
  - 按住鼠标的中键，随意拖动就可以按块选择代码
  - 自动提示的小黄灯泡就是可以提示，可以设置为option+enter匹配idea
  - 重构：ctrl+shift+R
  - 搜索:command+shift+f
  - git 源码：comman+9 源码管理
  - 调试：command+5
  - 扩展：command+shift+x

- 自定义代码模板

  - command+ shift + p
  - 配置用户代码片段
  - name：就是一个名称，没有什么含义
  - prefix：前缀
  - doby：打印出的字符
  - description：描述
  - ${1:label}：可以为变量设置默认值
  - ${1:$CLIPBOARD}：默认值可以是剪切板中的内容

- 编辑页面

  - 代码折叠：option+command+[
  - 代码展开：option+command+]
  - 关闭小地图：editor.minimap.renderCharacter
  - 打开面包屑：breadcrumbs.enabled

- 搜索

  - 搜索属性：
    - 大小写敏感
    - 全词匹配
    - 正则表达式匹配（JavaScript引擎）
  - 极度搜索：command+f
  - 替换：command+R
    - 使用enter
  - 选中字符：直接 command+G 效果和comman+f相同
  - command+shift +F 全文搜索

- 自定义编辑器

  - 设置行号：可以设置整个文件的第几行，也可以设置相对于当前行是第几行
  - 设置显示空格或者制表符，editor.renderWhitespace: all
  - 设置编辑器中的几个竖线：editor.renderIndentGuides .设置行书写的限制，例如120个字符
  - 关闭小地图功能minimap
  - 设置光标的定制：editor.cursorBlinking
  - 设置行号：editor.renderLineHighlight: all
  - 自动检测：Detect Indentation 自动检测空格符和制表符
  - 自动保存：editor.formatOnSave: true
  - 保存延迟：files.autoSaveDelay
  - 自动格式化： Format On Type
  - 主题使用：OneDarkProBold

- 组件

  - 问题面板
  - 输出面板
  - 调试面板
  - 终端

- 命令面板

  - … 转到文件
  - \# 转到工作区中的符号
  - \> 显示并运行命令
  - debug：调试配置
  - edt：显示所有一打开的编辑器
  - edt active：显示活动组中的编辑器
  - ext：管理扩展
  - ext install：安装扩展库
  - task：运行任务
  - term：显示所有一打开的终端
  - view：打开视图、
  - : 冒号：跳转到第几行
  - @ 跳转到文件中的方法

- muti-root workspace

  - 多文件工作区
  - 即使当我们同时开发不同的项目的时候，我们就可以使用多文件工作区，
  - 在命令行面板中，将文件夹添加到工作区中
  - 同时可以，将文件夹另存为
  - 多个工作区之间的切换使用 Ctrl + W
  - .vscode 文件夹可以自定义当前文件夹的一些规范，便于自定义统一开发环境

- 版本管理

  - 主要使用git进行版本控制
  - 文件变动时会有标记，以及对比
  - 使用Git搜索可以看见命令提示

- 终端

  - 配置对应的主题
    - 字体类型：Menlo for Powerline
    - 安装步骤
      - $cd /Library/Fonts
      - $sudo git clone https://github.com/abertsch/Menlo-for-Powerline.git

- WorkFlow

  - 执行任务

  - 针对于node，maven，typescripte，等在工程下面会有特殊的文件存在，vscode会自动检测，这样当我们在命令面板下面输入配置任务的时候，就会显示

  - 当我们选择node install 的时候，就会生成如下一个 task.json 的文件：

    ![img](https://img.mubu.com/document_image/c0675526-ed15-4e45-b4c4-dcf6b6c08f3a-172511.jpg)

    - version：版本
    - task：
      - type：代表是那种类型
      - script：代表执行的什么操作
      - problemMatcher：是一个对象，在这个对象中定义了如何去分析任务运行的结果
      - label：代表了任务的名字，描述任务的作用
      - presentation: 控制任务运行的时候，是否要自动调用运行的界面，让我们看到结果，或者是否要创建一个窗口执行任务；
      - options：
        - cwd：用户控制任务执行时候的几个配置，控制任务脚本运行文件夹地址，
        - env：控制环境变量
        - shell：shell 使用那个环境执行

  - 结果分析

    - $tsc，用于分析 TypeScript 编译的结果，$tsc-watch 则是用于分析运行在观察模式下的 TypeScript 编译器的结果；
    - $jshint用于分析 JSHint 的结果，$jshint-stylish 用于分析 JSHint Stylish 的运行结果；
    - $eslint-compact 和 $eslint-stylish 分别用于分析 ESLint Compact 和 ESLint Stylish；
    - $go 是 Go 编译器的分析器；
    - $mscompile 用于分析 CSharp 和 VB 的编译结果；
    - $lessc 是用于分析 Lessc 的运行结果的；
    - $node-sass 用于分析 Node Sass 编译结果。

  - 自定义任务分析

    - 文件地址 行号 列号 错误的重要级别 错误信息

- Debugger

  - vscode 用于调试的配置是一个 launch.json 文件

    ![img](https://img.mubu.com/document_image/859510af-1288-4bfc-b68c-db86c2c78d4b-172511.jpg)

    - type： 代表了调试的类型决定了VS Code 使用哪种调试插件来调试代码
    - request：代表如何启动调试器，
      - 如果代码已经运行起来了，则可以将它设置为attach，那么我们则是使用调试器来调试这个已有的代码进程
      - 如果是launch，则意味着我们会使用调试器直接启动代码进行调试
    - name：配置的名字
    - program：告诉调试器，调试文件的位置

  - 通用属性

    - program 一般用于指定将要调试的文件。
    - stopOnEntry，当调试器启动后，是否在第一行代码处暂停代码的执行。这个属性非常方便，如果没有设置断点而代码执行非常快的话，我们就会像文章的最开头那样，代码调试一闪而过，而没有办法在代码执行的过程中暂停了。而设置了 stopOnEntry 后，代码会自动在第一行停下来，然后我们就可以继续我们的代码调试了。
    - args 参数。相信你应该记得在前面任务系统配置的文章里，我已经说明了可以使用 args 来控制传入任务脚本的参数，同样的，我们也可以通过 args 来把参数传给将要被调试的代码。
    - env 环境变量。大部分调试器都使用它来控制调试进程的特殊环境变量。
    - cwd 控制调试程序的工作目录。
    - port 是调试时使用的端口。

  - 总结来说

    - 借助模板和智能提示，尽可能利用调试插件给我们的提示和文档
    - 第二：试着记住和学习通用的配置属性和技巧

- 工作区快捷键

  - 对于编辑快捷键的处理 不仅仅是处理 快捷键的简单设置，我们可以高级自定义的设置

  - 对于不同场景的按键是可以重复的，但是此时我们就是如何区分不同的场景

    https://code.visualstudio.com/docs/getstarted/keybindings#_when-clause-contexts

    - Editor contexts
    - editorFocus An editor has focus, either the text or a widget.
    - editorTextFocus The text in an editor has focus (cursor is blinking).
    - textInputFocus Any editor has focus (regular editor, debug REPL, etc.).
    - inputFocus Any text input area has focus (editors or text boxes).
    - editorHasSelection Text is selected in the editor.
    - editorHasMultipleSelections Multiple regions of text are selected (multiple cursors).
    - editorReadOnly The editor is read only.
    - editorLangId True when the editor’s associated language Id matches. Example: “editorLangId == typescript”.
    - isInDiffEditor The active editor is a difference editor.
    - Operating system contexts
    - isLinux True when the OS is Linux
    - isMac True when the OS is macOS
    - isWindows True when the OS is Windows
    - Mode contexts
    - inDebugMode A debug session is running.
    - inSnippetMode The editor is in snippet mode.
    - inQuickOpen The Quick Open drop-down has focus.
    - Resource contexts
    - resourceScheme True when the resource Uri scheme matches. Example: “resourceScheme == file”
    - resourceFilename True when the Explorer or editor filename matches. Example: “resourceFilename == gulpfile.js”
    - resourceExtname True when the Explorer or editor filename extension matches. Example: “resourceExtname == .js”
    - resourceLangId True when the Explorer or editor title language Id matches. Example: “resourceLangId == markdown”
    - Explorer contexts
    - explorerViewletVisible True if Explorer view is visible.
    - explorerViewletFocus True if Explorer view has keyboard focus.
    - filesExplorerFocus True if File Explorer section has keyboard focus.
    - openEditorsFocus True if OPEN EDITORS section has keyboard focus.
    - explorerResourceIsFolder True if a folder is selected in the Explorer.
    - Editor widget contexts
    - findWidgetVisible Editor Find widget is visible.
    - suggestWidgetVisible Suggestion widget (IntelliSense) is visible.
    - suggestWidgetMultipleSuggestions Multiple suggestions are displayed.
    - renameInputVisible Rename input text box is visible.
    - referenceSearchVisible Peek References peek window is open.
    - inReferenceSearchEditor The Peek References peek window editor has focus.
    - config.editor.stablePeek Keep peek editors open (controlled by editor.stablePeeksetting).
    - quickFixWidgetVisible Quick Fix widget is visible.
    - parameterHintsVisible Parameter hints are visible (controlled by editor.parameterHints setting).
    - parameterHintsMultipleSignatures Multiple parameter hints are displayed.
    - Integrated terminal contexts
    - terminalFocus An integrated terminal has focus.
    - Global UI contexts
    - notificationFocus Notification has keyboard focus.
    - notificationCenterVisible Notification Center is visible at the bottom right of VS Code.
    - notificationToastsVisible Notification toast is visible at the bottom right of VS Code.
    - searchViewletVisible Search view is open.
    - sidebarVisible Side Bar is displayed.
    - sideBarFocus Side Bar has focus.
    - panelFocus Panel has focus.
    - editorIsOpen True if one editor is open.
    - inZenMode Window is in Zen Mode.
    - inDebugRepl Focus is in the Debug Console REPL.
    - textCompareEditorVisible At least one diff (compare) view is visible.
    - workspaceFolderCount Count of workspace folders.
    - replaceActive Search view Replace text box is open.
    - view True when view identifier matches. Example: “view == myViewsExplorerID”.
    - viewItem True when viewItem context matches. Example: “viewItem == someContextValue”.

  - when 条件规则的使用

    - ! 取反。比如我们希望当光标不在编辑器里时，绑定一个快捷键，那么我们可以使用 !editorFocus，使用 ！进行取反。
    - == 等于。when 条件值除了是 boolean 以外，也可以是字符串。比如 resourceExtname 对应的是打开的文件的后缀名，如果我们想给 js 文件绑定一个快捷键，我们可以用 “resourceExtname == .js”。
    - && And 操作符。我们可以将多个条件值组合使用，比如我希望当光标在编辑器里且编辑器里正在编辑的是 js 文件，那么我可以用 “editorFocus && resourceExtname == .js”。
    - =~ 正则表达式。还是使用上面的例子，如果我要检测文件后缀是不是 js，我也可以写成 “resourceExtname =~ /js/”，通过正则表达式来进行判断。

  - 删除快捷键，就是在command的命令前面：添加‘-’

- 基础语言支持

  - JSON

    - 支持Schema

      ![img](https://img.mubu.com/document_image/ccb15dc7-594b-4f6f-929b-1e558d4488b2-172511.jpg)

  - Markdown

    - 可以自定义样式格式

      ![img](https://img.mubu.com/document_image/5fbf6638-0123-468c-bc2f-39bf9be7caf6-172511.jpg)

  - JavaScript

    - 类型提示
      - JsDoc
    - 自动模块引用
    - 自动模块更新（自动修复文件路径）
    - 代码审查 tsconfig、checkJs
    - NodeJs
    - 记录点Logpoints
      - 对于记录的console.log，在对应的行号右击，
      - 点击添加记录点，可以自己类似console进行日志输出

  - GO

    - 官方插件
    - 安装Go环境变量、goPath

  - Java

    - Java Extension Pack 打包安装
    - 调试
      - 可以自己设置调试的开始方法

  - Python

  - C#

  - HTML CSS

    - 取色器 Color Picker
    - Emmet
      - Child: > 子节点操作符
      - 兄弟节点操作符 Sibling: +
      - 乘法操作 Multiplication: *
      - Class Name, ID
      - \#page>div.logo+ul#navigation>li*5>a{Item $}
    - 展开缩写：p10
    - 建议列表：
    - 使用缩写包围
    - 多光标操作
    - 如何在其他语言中使用Emmet
      - “emmet.includeLanguages”: {
        - “javascript”: “javascriptreact”,
        - “vue-html”: “html”,
        - “razor”: “html”,
        - “plaintext”: “jade”
      - }

- 深度定制自己的主题

  - 固定UI视图

    - “workbench.sideBar.location”: “right”

  - 修改工作区配色

    ```json
    {
        "statusBar.background": "#666666",
        "panel.background": "#555555",
        "sideBar.background": "#444444"
    }
    ```

- 修改编辑器配色

  ```json
  "workbench.colorCustomizations": {
      "[Monokai]": {
          "statusBar.background": "#666666",
          "panel.background": "#555555",
          "sideBar.background": "#444444"
      },
  }
  ```

```
- 基本类型颜色修改
- TextMate 规则修改
```

- 插件推荐

  - GIT
    - gitlens
    - RemoteHub
    - GitHub Pull Request
  - 工作区
    - Settings Sync
    - Project Manager
  - 编辑器
    - VIM
    - Rainbow Brackets
    - Indent Rainbow
    - Pigment
    - Import Cost
  - Debug
    - Debug for Chrome
  - 其他
    - Rest Client
    - Code Runner
    - Live Share
    - Live Share Audio

- 配置、部署、调试 Docker

  - 这个没什么难点，关键都会使用命令时，提供图形化界面的时候，我们可以简化输入一些命令

  - 还有就是一个远程的调试

    - 将调试的类型设置为 attach

      ```json
      {
          "version": "0.2.0",
          "configurations": [
              {
                  "type": "node",
                  "request": "attach",
                  "name": "Docker: Attach to Node",
                  "port": 9229,
                  "address": "localhost",
                  "localRoot": "${workspaceFolder}",
                  "remoteRoot": "/usr/src/app",
                  "protocol": "inspector"
              }
          ]
      }
      ```

- 对于docker自身的容器管理使用docker-compose
- docker-compose up
- docker-compose start
- docker-compose stop
- 自动生成dockefile文件

- Tips & Tricks
  - 跳转 F12
  - 跳转到上一次编辑位置 alt + command + ←
  - 跳转到下一次编辑位置 alt + command + →
  - 复制当前行
  - 移动编辑窗口
  - 鼠标打开新编辑器窗口
  - Font ligatures 字体连字
  - 更快速的自动补全
  - 文件删除
  - 创建多层次文件夹和文件
  - 为不同的工作区设置标题栏颜色
  - 复制搜索结果
  - 固定调试工具条位置
  - 挑选键盘的设置 tenkeyless
- 插件开发

### 

