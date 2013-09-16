import 'dart:html';
import 'package:js/js.dart' as js;

UListElement posts;
UListElement comm;
InputElement subRedIn;

void main() {
  posts = query('#posts');
  comm = query('#comm');
  subRedIn = query('#subRed');
  AnchorElement reload = query('#reload');
  subRedIn.onChange.listen(prepPosts);
  reload.onClick.listen(prepPosts);
  String url = window.location.href;
  String sub = window.localStorage['sub'];
  var index =url.lastIndexOf("#");
  if (index > 0 && url.length-index-1 > 0)
  {
    sub = url.substring(index + 1);
    window.localStorage['sub'] = sub;
  }

  if(sub ==""){
       sub = "all";
  }
  var PostUrl = "https://ssl.reddit.com/r/$sub.json?limit=40&jsonp=getPosts";
  js.context.getPosts= new js.Callback.once(loadPosts);
  ScriptElement PostScript = new ScriptElement();
  PostScript.src = PostUrl;
  PostScript.type= "text/javascript";
  document.body.nodes.add(PostScript);
  comm.onClick.listen(toggleList);
}
void prepPosts(Event e)
{
  var sub = subRedIn.value;
  if(sub == "")
    sub = window.localStorage['sub'];
  else
    window.localStorage['sub'] = sub;

  var PostUrl = "https://ssl.reddit.com/r/$sub.json?limit=40&jsonp=getPosts";
  js.context.getPosts= new js.Callback.once(loadPosts);
  ScriptElement PostScript = new ScriptElement();
  PostScript.src = PostUrl;
  PostScript.type= "text/javascript";
  document.body.nodes.add(PostScript);
}
void loadPosts(var data)
{

  var results = data.data.children;
  int length = results.length;
  posts.innerHtml = '';
  for(int i = 0; i < length; i++)
  {
    var postInfo = results[i].data;
    addPost(posts, postInfo);
  }
  query("#posts").scrollIntoView(ScrollAlignment.TOP);

}

void loadCommentData(var data)
{
  comm.innerHtml = '';
  var results = data[0];
  selfText(results);
  results = data[1];
  addComment(comm,results);
  query("#title").scrollIntoView(ScrollAlignment.TOP);

}
void loadArticleData(var data)
{
  comm.innerHtml = '';
  query("#title").innerHtml = "";
  query("#selfText").innerHtml = "";
  query("#title").innerHtml = "<h1>${data.title}</h1>";
  query("#selfText").innerHtml = '<a target=_blank href="${data.url}">Full Article</a>';
  try{
    comm.innerHtml = data.content;
  } catch(e){
    comm.innerHtml = "Something Went Wrong!";
  }
  query("#title").scrollIntoView(ScrollAlignment.TOP);

}
void selfText(info)
{
  String selfText, title;
  DivElement selfTextDiv = query("#selfText");
  DivElement titleDiv = query("#title");
  selfTextDiv.innerHtml = '';
  var results = info.data.children;
  try{
    selfText = escapeString(results[0].data.selftext_html);
  }
  catch(e){
    selfText = "";

  }
  title =   results[0].data.title;
  selfTextDiv.appendHtml("<p> <h3>$selfText </h3> </p>");
  titleDiv.innerHtml = ("<h1>$title</h1>");
}
void addComment(list, info)
{
  var results = info.data.children;
  int length = results.length;
  for(int i = 0; i < length; i++)
  {
    if(results[i].kind != "t1")
    {
      continue;
    }
    var postInfo = results[i].data;
    var newPost = new LIElement();
    DateTime time = new DateTime.fromMillisecondsSinceEpoch(postInfo.created_utc*1000, isUtc: true);
    var timeDiff=time.difference(new DateTime.now()).inHours.abs();
    var hours = "hr";
    if(timeDiff != 1)
      hours += "s";

    timeDiff = "${timeDiff.toString()} $hours";

    String str = "<p>[${postInfo.ups - postInfo.downs}] <u>${postInfo.author}</u>  (${timeDiff} ago)</p>" + postInfo.body_html;
    newPost.innerHtml = escapeString(str);

    list.children.add(newPost);
    if(postInfo.replies != "")
    {
      int len = postInfo.replies.data.children.length;
      UListElement l = new UListElement();
      l.className = "a";
      if(postInfo.replies.data.children[0].kind == "t1")
      {
        l.onClick.listen(toggleList);
        list.children.add(l);
      }
      addComment(l,postInfo.replies);
    }

   }
}
void prepComment(MouseEvent e)
{
  var id = e.target.id;
  js.context.getComments= new js.Callback.once(loadCommentData);
  ScriptElement CommScript = new ScriptElement();
  String url = "https://ssl.reddit.com${id}.json?&jsonp=getComments";
  CommScript.src = url;
  query("#title").innerHtml = "";
  query("#selfText").innerHtml = "";
  comm.innerHtml = 'loading...';
  document.body.nodes.add(CommScript);
}
void prepArticle(MouseEvent e)
{
  var id = e.target.id;
  js.context.getArticle= new js.Callback.once(loadArticleData);
  ScriptElement script = new ScriptElement();
  String url = "https://www.readability.com/api/content/v1/parser?url=${id}&token=e17f7b97af131aa20aad90afb1bc241bf2d53e36&callback=getArticle";
  script.src = url;
  query("#title").innerHtml = "";
  query("#selfText").innerHtml = "";
  comm.innerHtml = 'loading...';
  document.body.nodes.add(script);
}

void addPost(list,info)
{
  String url = info.url;
  var newPost = new LIElement();
  newPost.className = "postList";
  var c = new AnchorElement();
  var title = new AnchorElement();
  c.className = "postComm";
  c.innerHtml = "comments (${info.num_comments})";
  c.id = info.permalink;
  c.onClick.listen(prepComment);
  c.href = "#";
  if(url.contains("reddit.com/r/"))
  {
    title.id = info.permalink;
    title.onClick.listen(prepComment);
    title.href = "#";
  }
  else if(url.contains("imgur.com/") || url.contains("youtube.com"))
  {
    title.href = info.url;
    title.target = "_blank";

  }
  else
  {
    title.id = info.url;
    title.onClick.listen(prepArticle);
    title.href = "#";
  }
  title.innerHtml = info.title;
  newPost.append(title);
  newPost.appendHtml("<br>");
  newPost.append(c);
  newPost.appendHtml("<br>");
  //String str = "<a href=${info.url} target=_blank>${info.title}</a>  ";
  //newPost.innerHtml = str;
  list.children.add(newPost);

}
void toggleList(MouseEvent e)
{

}
String escapeString(String str)
{
  str = str.replaceAll("&amp;#39;", "'");
  str = str.replaceAll("&amp;quot;", '"');
  str = str.replaceAll("&gt;", '>');
  str = str.replaceAll("&lt;", '<');
  str = str.replaceAll("&amp;", "&");

  return str;
}
