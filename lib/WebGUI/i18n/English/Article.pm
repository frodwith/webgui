package WebGUI::i18n::English::Article;

our $I18N = {
	'11' => {
		message => q|(Select "Yes" only if you aren't adding &lt;br&gt; manually.)|,
		lastUpdated => 1031514049
	},

	'71' => {
		message => q|<P>Articles are the Swiss Army knife of WebGUI. Most pieces of static content can be added via the Article.  Dataforms are Wobjects, so they inherit the properties of both Wobjects and Assets.
<P>

NOTE: You can create a multi-paged article by placing the separator macro (&#94;-;) at various places through-out your article.  This works unless you are using a Make Page Printable style.

<P><b>^International("913","Template");</b><br>
Select a template from the list to layout your Wobject.  Each Wobject
may only use templates for their own namespace.  For example, Articles
can only use templates from the "Article" namespace.  Layouts can only
use templates from the "page" namespace.

<p><b>^International("1",Article");</b><br>
If you wish to add a link to your article, enter the title of the link in this field. 
<br><br>
<i>Example:</i> Google

<p><b>^International("8","Article");</b><br>
If you added a link title, now add the URL (uniform resource locater) here. 
<br><br>
<i>Example:</i> http://www.google.com

<p><b>^International("10","Article");</b><br>
If you're publishing HTML there's generally no need to check this option, but if you aren't using HTML and you want a carriage return every place you hit your "Enter" key, then check this option.

|,
		lastUpdated => 1110135832,
	},

	'7' => {
		message => q|Link Title|,
		lastUpdated => 1031514049
	},

	'1' => {
		message => q|Article|,
		lastUpdated => 1031514049
	},

	'72' => {
		message => q|Article Template|,
		lastUpdated => 1038794871
	},

	'28' => {
		message => q|View Responses|,
		lastUpdated => 1031514049
	},

	'61' => {
		message => q|Article, Add/Edit|,
		lastUpdated => 1066583066
	},

	'12' => {
		message => q|Edit Article|,
		lastUpdated => 1031514049
	},

	'8' => {
		message => q|Link URL|,
		lastUpdated => 1031514049
	},

	'73' => {
		message => q|The following template variables are available for article templates.
<p/>

<b>new.template</b><br>
Articles have the special ability to change their template so that you can allow users to see different views of the article. You do this by creating a link with a URL like this (replace 999 with the template Id you wish to use):<p>
&lt;a href="&lt;tmpl_var new.template&gt;999"&gt;Read more...&lt;/a&gt;
<p>
<b>description</b><br>
The paginated description.
<p>

<b>description.full</b><br>
The full description without any pagination.
<p>

<b>description.first.100words</b><br>
The first 100 words in the description. Words are defined as characters separated by whitespace, so HTML entities and tags count as words.
<p>

<b>description.first.75words</b><br>
The first 75 words in the description. Words are defined as characters separated by whitespace, so HTML entities and tags count as words.
<p>

<b>description.first.50words</b><br>
The first 50 words in the description. Words are defined as characters separated by whitespace, so HTML entities and tags count as words.
<p>

<b>description.first.25words</b><br>
The first 25 words in the description. Words are defined as characters separated by whitespace, so HTML entities and tags count as words.
<p>

<b>description.first.10words</b><br>
The first 10 words in the description. Words are defined as characters separated by whitespace, so HTML entities and tags count as words.
<p>

<b>description.first.paragraph</b><br>
The first paragraph of the description. The first paragraph is determined by the first carriage return found in the text.
<p>

<b>description.first.2paragraphs</b><br>
The first two paragraphs of the description. A paragraph is determined by counting the carriage returns found in the text.
<p>

<b>description.first.sentence</b><br>
The first sentence in the description. A sentence is determined by counting the periods found in the text.
<p>

<b>description.first.2sentences</b><br>
The first two sentences in the description. A sentence is determined by counting the periods found in the text.
<p>

<b>description.first.3sentences</b><br>
The first three sentences in the description. A sentence is determined by counting the periods found in the text.
<p>

<b>description.first.4sentences</b><br>
The first four sentences in the description. A sentence is determined by counting the periods found in the text.
<p>


<b>attachment.box</b><br/>
Outputs a standard WebGUI attachment box including icon, filename, and attachment indicator.
<p/>

<b>attachment.icon</b><br/>
The URL to the icon image for this attachment type.
<p/>

<b>attachment.name</b><br/>
The filename for this attachment.
<p/>

<b>attachment.url</b><br/>
The URL to download this attachment.
<p/>

<b>image.thumbnail</b><br/>
The URL to the thumbnail for the attached image.
<p/>

<b>image.url</b><br/>
The URL to the attached image.
<p/>

<b>linkTitle</b><br/>
The title of the link added to the article.
<p/>

<b>linkURL</b><br/>
The URL for the link added to the article.
<p/>

<b>post.label</b><br/>
The translated label to add a comment to this article.
<p/>

<b>post.URL</b><br/>
The URL to add a comment to this article.
<p/>

<b>replies.count</b><br/>
The number of comments attached to this article.
<p/>

<b>replies.label</b><br/>
The translated text indicating that you can view the replies.
<p/>

<b>replies.url</b><br/>
The URL to view the replies to this article.
<p/>
|,
		lastUpdated => 1106783944
	},

	'24' => {
		message => q|Post Response|,
		lastUpdated => 1031514049
	},

	'10' => {
		message => q|Convert carriage returns?|,
		lastUpdated => 1031514049
	},

};

1;
