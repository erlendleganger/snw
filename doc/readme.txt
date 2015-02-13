Build a new version of the site
-------------------------------
- bash bin/web-driver.sh -a build
- open the site http://192.168.239.132 in a web browser
  review the changes

Add a new article/page to a release
-----------------------------------
- Establish the release(s) the page shall belong to
- Establish a good file name for the page (it will be visible to the users)
- Copy a template into the new page:
   cp misc/topic-template.html.md.eco docpad/src/document/release/topic/my-topic-name.html.md.eco
- Edit the new topic:
  - Edit the title: field
  - Edit the date: field
  - Edit the release-list: field; follow the pattern, newest releases first
  - Delete the dummy body and add your contents
- Build and check (see above)
- When done:
  export GIT_AUTHOR_NAME="Your Name"
  export GIT_AUTHOR_EMAIL=youremailaddress@some.domain.int
  git add ....
  git commit ....
  git push

