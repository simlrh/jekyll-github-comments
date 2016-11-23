# Jekyll GitHub Comments

A Jekyll plugin to provide static site comments via GitHub pull requests.

When a user clicks "Reply" on your blog, they're linked to the GitHub repo of your website, automatically forked and ready to edit online at the correct file and line number. Once they've added their comment directly to the source code they can send a pull request to have their comment merge into the official repo and put live.

jekyll-github-comments adds Liquid template tags to make adding comments easier for site maintainers and visitors.

## Configuration

Add a `github_comments` section to `_config.yaml`. The only required key is `repo`, other keys have the following defaults:

    github_comments:
      repo: gituser/gitrepo
      branch: master
      comment_template: comments.html
      comments_template: comments.html

## Template tags

The plugin provides two template tags: `{% responses %}` (a simple container for the comments section and any nested threads) and `{% response %}` (a block tag containing the comment, with any metadata passed as tag arguments).

    <!-- Adds an empty comment section to the page -->
    {% responses %}
    {% endresponses %}

    <!-- Top level comments -->
    {% responses %}
      {% response author="Steve" email="steve@nourish.je" date="2016-11-23 16:08:32" param="value" %}
        This is a comment
      {% endresponse %}
      {% response author="Steve" email="steve@nourish.je" date="2016-11-23 16:08:32" param="value" %}
        So is this
      {% endresponse %}
    {% endresponses %}

    <!-- Threaded comments -->
    {% responses %}
      {% response author="Steve" email="steve@nourish.je" date="2016-11-23 16:08:32" param="value" %}
        This is a comment
        {% responses %}
          {% response author="Steve" email="steve@nourish.je" date="2016-11-23 16:08:32" param="value" %}
            This is a reply
            {% responses %}
              {% response author="Steve" email="steve@nourish.je" date="2016-11-23 16:08:32" param="value" %}
                You can nest them as deep as you like
              {% endreponse %}
            {% endresponses %}
          {% endresponse %}
          {% response author="Steve" email="steve@nourish.je" date="2016-11-23 16:08:32" param="value" %}
            A second reply to the top comment
          {% endresponse %}
        {% endresponses %}
      {% endresponse %}
    {% endresponses %}

## Templates

There must be a two templates in the Jekyll includes path; pnefor individual comments and one for the comments section as a whole. Filenames can be set in `_config.yaml`.

The following variables are available:

### Comments template

| Variable | Description |
| --- | --- |
| {{ subcomments }} | Boolean; false if this is the top level of comments |
| {{ comments }} | The comments on this thread level |
| {{ comment\_url }} | Link to the file and line no of the comment section on GitHub's edit page |


### Comment template

| Variable | Description |
| --- | --- |
| {{ comment._anything_ }} | Any parameter used inside {% response param="value" %} - use for comment metadata like author name, email, date, etc |
| {{ comment.content }} | Comment body (use markdownify filter for markdown support) |
| {{ comment.reply\_url }} | Link to the file and line no of the comment on GitHub's edit page |
| {{ comment.replies }} | Threaded comment replies formatted according to comments template |

## Example templates

See [this gist](https://gist.github.com/simlrh/c56573aa19d1b707f6cc086910379e5c) for examples of comment and comments templates.
