<!--
    html.dsl - stylesheets for HTML output.
    Stolen from SGMLtools
-->

<!DOCTYPE style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN" [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN" CDATA dsssl>
]>
<style-sheet>

<style-specification id="html" use="docbook">
<style-specification-body> 


(define %html-ext% ".html")
(define %root-filename% "policy")
(define %generate-article-toc% #t)
(define %generate-article-titlepage% #t)
(define %use-id-as-filename% #t)
; (define %gentext-nav-use-tables%  #f)

;; Add other customization here


</style-specification-body>
</style-specification>

<external-specification id="docbook" document="docbook.dsl">
</style-sheet>
