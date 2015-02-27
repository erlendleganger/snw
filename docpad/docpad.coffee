# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig = {

        # =================================
        # source for external/vendor files
        filesPaths: [ 'public' ]
        layoutsPaths: [ 'layout' ]
        documentsPaths: [ 'document' ]
        
        # =================================
        # Template Data
        # These are variables that will be accessible via our templates
        # To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

        templateData:

                # Specify some site properties
                site:
                        # The production url of our website
                        url: "http://website.com"

                        # Here are some old site urls that you would like to redirect from
                        oldUrls: [
                                'www.website.com',
                                'website.herokuapp.com'
                        ]

                        # The default title of our website
                        title: "SSC Support Web"

                        # The website description (for SEO)
                        description: """
                                When your website appears in search results in say Google, the text here will be shown underneath your website's title.
                                """

                        # The website keywords (for SEO) separated by commas
                        keywords: """
                                place, your, website, keywoards, here, keep, them, related, to, the, content, of, your, website
                                """

                        # The website author's name
                        author: "Erlend Leganger"

                        # The website author's email
                        email: "eleganger@necccis.ais.nato.int"

                        # Styles - currently not used; put this back into
                        # default layout to use this section:
                        # <%- @getBlock('styles').add(@site.styles).toHTML() %>
                        styles: [
                                #main look and feel:
                                #spacelab from bootswatch.com is nice...
                                "/vendor/bootswatch/style/bootstrap-spacelab.css"
                                #"/style/bootstrap-flatly.css"
                                #standard bootstrap:
                                #"/style/twitter-bootstrap.css"

                                #local style settings:
                                "/style/style.css"
                                
                                #syntax highlighting:
                                #"/style/highlight/googlecode.css"
                                #"/style/highlight/github.css"
                                "/vendor/isagalaev/highlight/style/solarized_light.css"
                                #"/style/highlight/solarized_dark.css"
                                
                                #tablesorter:
                                "/vendor/cbach/tablesorter/style/blue/style.css"
                        ]

                        # Scripts - currently not used; put this back into
                        # default layout to use this section:
                        #<%- @getBlock('scripts').add(@site.scripts).toHTML() %>
                        scripts: [
                                #"//cdnjs.cloudflare.com/ajax/libs/jquery/1.10.2/jquery.min.js"
                                "/vendor/jquery/jquery-1.10.2.js"
                                "/vendor/cbach/tablesorter/jquery.tablesorter.js"
                                #"//cdnjs.cloudflare.com/ajax/libs/modernizr/2.6.2/modernizr.min.js"
                                "/vendor/modernizr/2.6.2/modernizr.min.js"
                                "/vendor/twitter-bootstrap/dist/js/bootstrap.min.js"
                                "/scripts/script.js"
                        ]



                # -----------------------------
                # Helper Functions

                # Get the prepared site/document title
                # Often we would like to specify particular formatting to our page's title
                # we can apply that formatting here
                getPreparedTitle: ->
                        # if we have a document title, then we should use that and suffix the site's title onto it
                        if @document.title
                                "#{@document.title} | #{@site.title}"
                        # if our document does not have it's own title, then we should just use the site's title
                        else
                                @site.title

                #block of text to be used in release tocs
                getHandwritingTocBlock: (document) ->
                   "<p>Use the links below or read it all in <a href='../#{document.releaseid.replace(/\./g,'')}-all/'>one single page</a>:</p>\n<ul>\n"+
                   (for topic,cnt in @getCollection("documents").findAllLive({type:'handwriting'},[{date:-1}]).toJSON()
                      "<li>[#{@getDateYYYYMMDD(topic.date)}] <a href='#{topic.url}'>#{topic.title}</a></li>").join('\n')+
                   "</ul>\n"

                #block of text to be used in release tocs
                getReleaseTocBlock: (document) ->
                   "<p>Use the links below or read it all in <a href='../#{document.releaseid.replace(/\./g,'')}-all/'>one single page</a>:</p>\n<ul>\n"+
                   (for topic,cnt in @getCollection("documents").findAllLive({type:'release-topic',releaselist: $has: document.releaseid},[{date:-1}]).toJSON()
                      "<li>[#{@getDateYYYYMMDD(topic.date)}] <a href='#{topic.url}'>#{topic.title}</a></li>").join('\n')+
                   "</ul>\n"

                #block of text to be used in release topics
                getReleaseAllBlock: (document) ->
                   "<p>Table of contents:</p>\n<ul>\n"+
                   (for topic,cnt in @getCollection("documents").findAllLive({type:'release-topic',releaselist: $has: document.releaseid},[{date:-1}]).toJSON()
                      "<li><a href='##{cnt}'>#{topic.title}</a></li>").join('\n')+
                   "</ul>\n"+
                   (for topic,cnt in @getCollection("documents").findAllLive({type:'release-topic',releaselist: $has: document.releaseid},[{date:-1}]).toJSON()
                      "<hr/>\n<a style='text-decoration:none;cursor:default' name='#{cnt}'><h3 style='padding-top: 55px; margin-top: -55px;'>#{topic.title}</h3></a>\n#{topic.contentRenderedWithoutLayouts}").join('\n')
                   
                #block of text to be used in release topics
                getReleaseTopicBlock: (document) ->
                   "Last updated: #{@getDateYYYYMMDD(document.date)}. "+
                   "Applicable releases: #{('['+id+'](/release/'+id.replace(/\./g,'')+'-toc/)' for id in @document.releaselist).join(', ')}."
                
                #format dates in yyyy-mm-dd format
                getDateYYYYMMDD: (date) ->
                   month=1+date.getMonth()
                   month="0"+month if month<10
                   day=date.getDate()
                   day="0"+day if day<10
                   "#{date.getFullYear()}-#{month}-#{day}"

                # Get the prepared site/document description
                getPreparedDescription: ->
                        # if we have a document description, then we should use that, otherwise use the site's description
                        @document.description or @site.description

                # Get the prepared site/document keywords
                getPreparedKeywords: ->
                        # Merge the document keywords with the site keywords
                        @site.keywords.concat(@document.keywords or []).join(', ')


        # =================================
        # Collections
        # These are special collections that our website makes available to us

        collections:
                pages: (database) ->
                        database.findAllLive({pageOrder: $exists: true}, [pageOrder:1,title:1])

                sitetopics: (database) ->
                        database.findAllLive({type:'site'}, [date:-1])
                posts: (database) ->
                        database.findAllLive({tags:$has:'post'}, [date:-1])
                releases: (database) ->
                        database.findAllLive({tags:$has:'release'}, [date:-1])
                releaseindeces: (database) ->
                        database.findAllLive({tags:$has:'release-index'}, [date:-1])
                releasetopics: (database) ->
                        database.findAllLive({type:'release-topic'}, [date:-1])


        # =================================
        # Plugins

        plugins:
                downloader:
                        downloads: [
                                {
                                        name: 'Twitter Bootstrap'
                                        path: 'src/files/vendor/twitter-bootstrap'
                                        url: 'https://codeload.github.com/twbs/bootstrap/tar.gz/master'
                                        tarExtractClean: true
                                }
                        ]


        # =================================
        # DocPad Events

        # Here we can define handlers for events that DocPad fires
        # You can find a full listing of events on the DocPad Wiki
        events:

                # Server Extend
                # Used to add our own custom routes to the server before the docpad routes are added
                serverExtend: (opts) ->
                        # Extract the server from the options
                        {server} = opts
                        docpad = @docpad

                        # As we are now running in an event,
                        # ensure we are using the latest copy of the docpad configuraiton
                        # and fetch our urls from it
                        latestConfig = docpad.getConfig()
                        oldUrls = latestConfig.templateData.site.oldUrls or []
                        newUrl = latestConfig.templateData.site.url

                        # Redirect any requests accessing one of our sites oldUrls to the new site url
                        server.use (req,res,next) ->
                                if req.headers.host in oldUrls
                                        res.redirect(newUrl+req.url, 301)
                                else
                                        next()
}


# Export our DocPad Configuration
module.exports = docpadConfig
