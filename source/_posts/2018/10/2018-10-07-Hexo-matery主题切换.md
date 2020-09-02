---
title: Hexo-matery主题切换
author: HoldDie
tags: [博客,主题,Hexo]
top: false
date: 2018-10-05 19:43:41
categories: 博客
---

> 命运是被覆上朦胧的面纱，看得见，却永远也看不清。 ——我爱千泷

## 简记更换主题

### 切换主题

修改 Hexo 根目录下的`_config.yml`的`theme`的值：`theme: hexo-theme-matery`

### 新建分类 categories 页

`categories`页是用来展示所有分类的页面，如果在你的博客`source`目录下还没有`categories/index.md`文件，那么你就需要新建一个，命令如下：

```
hexo new page "categories"
```

编辑你刚刚新建的页面文件`/source/categories/index.md`，至少需要以下内容：

```
title: categories
date: 2018-09-30 17:25:30
type: "categories"
layout: "categories"
```

### 新建标签 tags 页

`tags`页是用来展示所有标签的页面，如果在你的博客`source`目录下还没有`tags/index.md`文件，那么你就需要新建一个，命令如下：

```
hexo new page "tags"
```

编辑你刚刚新建的页面文件`/source/tags/index.md`，至少需要以下内容：

```
title: tags
date: 2018-09-30 18:23:38
type: "tags"
layout: "tags"
```

### 新建关于我 about 页

`about`页是用来展示**关于我和我的博客**信息的页面，如果在你的博客`source`目录下还没有`about/index.md`文件，那么你就需要新建一个，命令如下：

```
hexo new page "about"
```

编辑你刚刚新建的页面文件`/source/about/index.md`，至少需要以下内容：

```
title: about
date: 2018-09-30 17:25:30
type: "about"
layout: "about"
```

### 配置tags页

`tags`页是用来展示所有标签的页面，如果在你的博客`source`目录下还没有`tags/index.md`文件，那么你就需要新建一个，命令如下：

```bash
hexo new page "tags"
```

编辑你刚刚新建的页面文件`/source/tags/index.md`，至少需要以下内容：

```yml
title: tags
date: 2018-09-10 18:23:38
type: "tags"
layout: "tags"
```

### 代码高亮

由于 Hexo 自带的代码高亮主题显示不好看，所以主题中使用到了[hexo-prism-plugin](https://github.com/ele828/hexo-prism-plugin)的 Hexo 插件来做代码高亮，安装命令如下：

```bash
npm i -S hexo-prism-plugin
```

然后，修改 Hexo 根目录下`_config.yml`文件中`highlight.enable`的值为`false`，并新增`prism`插件相关的配置，主要配置如下：

```yml
highlight:
  enable: false

prism_plugin:
  mode: 'preprocess'    # realtime/preprocess
  theme: 'tomorrow'
  line_number: false    # default false
  custom_css:
```

### 搜索

本主题中还使用到了[hexo-generator-search](https://github.com/wzpan/hexo-generator-search)的 Hexo 插件来做内容搜索，安装命令如下：

```bash
npm install hexo-generator-search --save
```

在 Hexo 根目录下的`_config.yml`文件中，新增以下的配置项：

```yml
search:
  path: search.xml
  field: post
```

### 中文链接转拼音

如果你的文章名称是中文的，那么 Hexo 默认生成的永久链接也会有中文，这样不利于`SEO`，且`gitment`评论对中文链接也不支持。我们可以用[hexo-permalink-pinyin](https://github.com/viko16/hexo-permalink-pinyin) Hexo 插件使在生成文章时生成中文拼音的永久链接。

安装命令如下：

```bash
npm i hexo-permalink-pinyin --save
```

在 Hexo 根目录下的`_config.yml`文件中，新增以下的配置项：

```yml
permalink_pinyin:
  enable: true
  separator: '-' # default: '-'
```

> **注**：除了此插件外，[hexo-abbrlink](https://github.com/rozbo/hexo-abbrlink)插件也可以生成非中文的链接。

### 修改社交链接

在主题文件的`/layout/_partial/footer.ejs`和`/layout/_partial/mobile-nav.ejs`文件中，你可以找到`social-link`的内容，可以在其中添加你需要的链接地址，增加内容如：

```html
<a href="https://github.com/blinkfox" class="tooltipped" target="_blank" data-tooltip="访问我的GitHub" data-position="top" data-delay="50">
    <i class="fa fa-github fa-lg"></i>
</a>
```

其中，社交图标（如：`fa-github`）你可以在[Font Awesome](https://fontawesome.com/icons)中搜索找到。以下是常用社交图标的标识，供你参考：

- Facebook: `fa-facebook`
- Twitter: `fa-twitter`
- Google-plus: `fa-google-plus`
- Linkedin: `fa-linkedin`
- Tumblr: `fa-tumblr`
- Medium: `fa-medium`
- Slack: `fa-slack`
- 新浪微博: `fa-weibo`
- 微信: `fa-wechat`
- QQ: `fa-qq`

> **注意**: 本主题中使用的`Font Awesome`版本为`4.5.0`。

## 文章Front-matter示例

以下为文章`Front-matter`的示例，所有内容均为**非必填**的。但是，仍然建议至少填写`title`的值，当然最好都填写上这些文章信息。

```yml
---
title: typora-vue-theme主题介绍
date: 2018-09-07 09:25:00
author: 赵奇
img: /source/images/xxx.jpg # 或者:http://xxx.com/xxx.jpg
tags:
  - Typora
  - Markdown
---
```

## 添加萌宠精灵

> [参考](https://blog.csdn.net/Aoman_Hao/article/details/82049821)链接
>
> 切换到博客目录然后输入：
>
> ```python
> #安装live2d
> npm install --save hexo-helper-live2d
> #安装萌宠module
> npm install live2d-widget-model-koharu 
> ```
>
> 添加在config文件内：
>
> ```shell
> live2d:
>   enable: true
>   scriptFrom: local
>   model:
>     use: live2d-widget-model-koharu
>   display:
>     position: right
>     width: 140
>     height: 260
>   mobile:
>     show: true
> ```

测试代码高亮：

```java
public static void main(){
    System.out.println("hell lulu");
}
```