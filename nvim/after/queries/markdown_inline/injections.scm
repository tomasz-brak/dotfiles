; extends

; Inject latex into latex_block (covers both $ and $$)
(latex_block) @injection.content
(#set! injection.language "latex")
