;;; igor-mode.el --- Major mode for editing Igor Pro procedure files

;; Copyright (C) 2011

;; Author:   Jason Yamada-Hanff <jyamada1@gmail.com>
;; Keywords: languages

;;; Commentary:
;;
;; Provides syntax highlighting, indentation, and
;; autoloading/unloading for Igor Pro procedure files.
;;
;; Written for Igor Pro 6.22A.
;;
;; Code was initially based heavily on Fred White's visual-basic-mode
;; <http://www.emacswiki.org/cgi-bin/wiki/visual-basic-mode.el>

;;; Install:
;;
;; Add the following lines to your .emacs (or initialization file):
;;
;; (add-to-list 'load-path "<path/to/igor-mode>")
;; (require 'igor-mode)

;;; Autoload/unload:
;;
;; Procedure files are set to read-only while they are loaded in
;; Igor. To work around this, when igor-mode saves an *.ipf file, it
;; unloads the procedure file from Igor, saves the files, and then
;; reloads the file. It should work on both Windows and Mac OS X
;; (Igor's supported platforms). On Windows, a Python distribution
;; with pywin32 is required (see igor-exec.el). I have not tested
;; these procedures very hard, so if you find a bug, let me know.
;;
;; Note: This behavior only works for files that are loaded by
;; #include, but that is how most procedure files ought to be loaded
;; anyhow.


;;; Code:

;; Custom variables
(defcustom igor-tab-width 4
  "Indent width for Igor"
  :type 'boolean
  :group 'igor)

(defcustom igor-use-autoreload t
  "Remove and re-insert files loaded in Igor when saving if non-nil"
  :type 'boolean
  :group 'igor)

(defvar igor-mode-hook nil)

(defvar igor-mode-map
  (let ((map (make-keymap)))
    (define-key map "\C-j" 'newline-and-indent)
    map)
  "Keymap for IgorPro major mode")

;; Autoload for igor files
(setq auto-mode-alist
      (append '(("\\.ipf$" . igor-mode)) auto-mode-alist))

(defun igor-wrap-re-startline (word-re)
  "Wrap a regexp to require WORD-RE to be at the start of a line"
  (concat "^[ \t]*" word-re))

;; Igor Pro Language Keywords and Built-ins
(defvar igor-procdec-keywords
  '("End" "EndMacro" "EndStructure"
    "Function" "Macro" "Picture"
    "Proc" "Structure" "Window")
  "IgorPro Procedure Declaration Keywords")

(defvar igor-procsub-keywords
  '("ButtonControl"
    "CheckBoxControl"
    "CursorStyle"
    "FitFunc"
    "Graph"
    "GraphMarquee"
    "GraphStyle"
    "GridStyle"
    "Layout"
    "LayoutMarquee"
    "LayoutStyle"
    "Panel"
    "PopupMenuControl"
    "SetVariableControl"
    "Table"
    "TableStyle")
  "IgorPro Procedure Subtype Keywords")

(defvar igor-objrefs-keywords
  '("DFREF"
    "FUNCREF"
    "NVAR"
    "STRUCT"
    "SVAR"
    "WAVE")
  "IgorPro Object Reference Keywords")

(defvar igor-flowcontrol-keywords
  '("AbortOnRTE"
    "AbortOnValue"
    "break"
    "catch"
    "continue"
    "default"
    "do"
    "while"
    "endtry"
    "for"
    "endfor"
    "if"
    "else"
    "elseif"
    "endif"
    "return"
    "strswitch"
    "case"
    "endswitch"
    "switch"
    "try")
  "IgorPro Flow Control Keywords")

(defvar igor-hash-keywords
  '("#define"
    "#if"
    "#elif"
    "#endif"
    "#ifdef"
    "#endif"
    "#ifndef"
    "#include"
    "#pragma"
    "#undef")
  "IgorPro Hash Keywords")

(defvar igor-other-keywords
  '("Constant"
    "DoPrompt"
    "GalleryGlobal"
    "IgorVersion"
    "IndependentModule"
    "Menu"
    "ModuleName"
    "MultiThread"
    "Override"
    "popup"
    "ProcGlobal"
    "Prompt"
    "root"
    "rtGlobals"
    "Static"
    "Strconstant"
    "String"
    "Submenu"
    "ThreadSafe"
    "Variable"
    "version")
  "IgorPro Other Keywords")

(defconst igor-builtin-functions
  '("AddListItem" "AnnotationInfo" "AnnotationList" "AxisInfo"
    "AxisList" "AxisValFromPixel" "BinarySearch" "BinarySearchInterp"
    "CTabList" "CheckName" "CleanupName" "ContourInfo"
    "ContourNameList" "ContourNameToWaveRef" "ContourZ"
    "ControlNameList" "CountObjects" "CreationDate" "CsrWave"
    "CsrWaveRef" "CsrXWave" "CsrXWaveRef" "DDEExecute" "DDEInitiate"
    "DDEPokeString" "DDEPokeWave" "DDERequestString" "DDERequestWave"
    "DDEStatus" "DDETerminate" "DataFolderDir" "DataFolderExists"
    "DateTime" "DimDelta" "DimOffset" "DimSize" "FakeData"
    "FindDimLabel" "FindListItem" "FontList" "FontSizeHeight"
    "FontSizeStringWidth" "FunctionList" "GetDataFolder"
    "GetDefaultFont" "GetDefaultFontSize" "GetDefaultFontStyle"
    "GetDimLabel" "GetFormula" "GetIndexedObjName" "GetRTErrMessage"
    "GetRTError" "GetRTStackInfo" "GetScrapText" "GetWavesDataFolder"
    "GetWindow" "IgorInfo" "ImageInfo" "ImageNameList"
    "ImageNameToWaveRef" "IndexedDir" "IndexedFile" "Inf"
    "ItemsInList" "LayoutInfo" "LowerStr" "MacroList" "MatrixDet"
    "MatrixDot" "MatrixRank" "MatrixTrace" "NVAR_Exists" "NaN"
    "NameOfWave" "NumVarOrDefault" "NumberByKey" "PICTInfo" "PICTList"
    "PadString" "PathList" "Pi" "PossiblyQuoteName" "ProcedureText"
    "RemoveByKey" "RemoveFromList" "RemoveListItem"
    "ReplaceNumberByKey" "ReplaceStringByKey" "SVAR_Exists"
    "ScreenResolution" "Secs2Date" "Secs2Time" "SelectNumber"
    "SelectString" "SortList" "StrVarOrDefault" "StringByKey"
    "StringFromList" "StringList" "StudentA" "StudentT" "TagVal"
    "TagWaveRef" "TextFile" "TraceFromPixel" "TraceInfo"
    "TraceNameList" "TraceNameToWaveRef" "UniqueName" "UpperStr"
    "VariableList" "WaveDims" "WaveExists" "WaveInfo" "WaveList"
    "WaveName" "WaveRefIndexed" "WaveType" "WaveUnits" "WhichListItem"
    "WinList" "WinName" "WinRecreation" "WinType" "XWaveName"
    "XWaveRefFromTrace" "abs" "acos" "acosh" "alog" "area" "areaXY"
    "asin" "asinh" "atan" "atan2" "atanh" "bessI" "bessJ" "bessK"
    "bessY" "betai" "binomial" "cabs" "ceil" "char2num" "cmplx"
    "cmpstr" "conj" "cos" "cosh" "cpowi" "date" "date2secs" "deltax"
    "e" "enoise" "erf" "erfc" "exists" "exp" "factorial" "faverage"
    "faverageXY" "floor" "gammln" "gammp" "gammq" "gnoise" "hcsr" "i"
    "ilim" "imag" "interp" "j" "jlim" "leftx" "limit" "ln" "log"
    "magsqr" "max" "mean" "min" "mod" "modDate" "note" "num2char"
    "num2istr" "num2str" "numpnts" "numtype" "p" "p2rect" "pcsr"
    "pnt2x" "poly" "poly2D" "q" "qcsr" "r" "r2polar" "real" "rightx"
    "round" "s" "sawtooth" "sign" "sin" "sinc" "sinh" "sqrt"
    "startMSTimer" "stopMSTimer" "str2num" "stringmatch" "strlen"
    "strsearch" "sum" "t" "tan" "tanh" "ticks" "time" "trunc" "vcsr"
    "x" "x2pnt" "xcsr" "y" "z" "zcsr")
  "Igor Pro 6 Built-in Functions")

(defconst igor-builtin-operations
  '("Abort" "AppendText" "AppendToGraph" "AppendToLayout"
    "AppendToTable" "AppendXYZContour" "AutoPositionWindow"
    "BackgroundInfo" "Beep" "BrowseURL" "BuildMenu" "Button" "Chart"
    "CheckBox" "CheckDisplayed" "Close" "CloseMovie" "ColorScale"
    "ColorTab2Wave" "ControlBar" "ControlInfo" "ControlNameList"
    "ControlUpdate" "ConvexHull" "Convolve" "CopyScales" "Correlate"
    "CtrlBackground" "CtrlFIFO" "Cursor" "CurveFit" "DefaultFont"
    "DelayUpdate" "DeletePoints" "Differentiate" "Dir" "Display"
    "DisplayHelpTopic" "DisplayProcedure" "DoAlert" "DoIgorMenu"
    "DoUpdate" "DoWindow" "DoXOPIdle" "DrawLine" "DrawOval" "DrawPICT"
    "DrawPoly" "DrawRRect" "DrawRect" "DrawText" "Duplicate"
    "DuplicateDataFolder" "EdgeStats" "Edit" "ErrorBars" "Execute"
    "Execute/P" "ExecuteScriptText" "FBinRead" "FBinWrite" "FFT"
    "FIFO2Wave" "FIFOStatus" "FReadLine" "FSetPos" "FStatus"
    "FTPDownload" "FTPUpload" "FastOp" "FindLevel" "FindLevels"
    "FindPeak" "FindPointsInPoly" "FindRoots" "FindSequence"
    "FindValue" "FuncFit" "FuncFitMD" "GetAxis" "GetMarquee"
    "GetSelection" "GetWindow" "GraphNormal" "GraphWaveDraw"
    "GraphWaveEdit" "GroupBox" "Hanning" "HideInfo" "HideProcedures"
    "HideTools" "Histogram" "IFFT" "ImageAnalyzeParticles"
    "ImageBlend" "ImageBoundaryToMask" "ImageEdgeDetection"
    "ImageFileInfo" "ImageFilter" "ImageGenerateROIMask"
    "ImageHistModification" "ImageHistogram" "ImageInfo"
    "ImageInterpolate" "ImageLineProfile" "ImageLoad"
    "ImageMorphology" "ImageNameList" "ImageNameToWaveRef"
    "ImageRemoveBackground" "ImageRotate" "ImageSave" "ImageSeedFill"
    "ImageStats" "ImageThreshold" "ImageTransform" "ImageWindow"
    "IndexSort" "InsertPoints" "Integrate" "IntegrateODE"
    "Interp3DPath" "KillBackground" "KillControl" "KillDataFolder"
    "KillFIFO" "KillPICTs" "KillPath" "KillStrings" "KillVariables"
    "KillWaves" "Label" "Layout" "Legend" "ListBox" "LoadData"
    "LoadPICT" "LoadWave" "Make" "MakeIndex" "MarkPerfTestTime"
    "MatrixConvolve" "MatrixEigenV" "MatrixFilter" "MatrixGaussJ"
    "MatrixLLS" "MatrixLUBkSub" "MatrixLUD" "MatrixLinearSolve"
    "MatrixMultiply" "MatrixSVBkSub" "MatrixSVD" "MatrixSchur"
    "MatrixSolve" "MatrixTranspose" "Modify" "ModifyContour"
    "ModifyGraph" "ModifyImage" "ModifyLayout" "ModifyPanel"
    "ModifyTable" "ModifyWaterfall" "MoveDataFolder" "MoveString"
    "MoveVariable" "MoveWave" "MoveWindow" "NewDataFolder" "NewFIFO"
    "NewFIFOChan" "NewImage" "NewLayout" "NewMovie" "NewNotebook"
    "NewPanel" "NewPath" "NewWaterfall" "Note" "Notebook" "Open"
    "OpenNotebook" "OpenProc" "Optimize" "PathInfo" "PauseForUser"
    "PauseUpdate" "PlayMovie" "PlayMovieAction" "PlaySnd" "PlaySound"
    "PopupContextualMenu" "PopupMenu" "PopupMenuControl" "Preferences"
    "Print" "PrintGraphs" "PrintLayout" "PrintNotebook" "Project"
    "PulseStats" "PutScrapText" "Quit" "ReadVariables" "Redimension"
    "Remove" "RemoveContour" "RemoveFromGraph" "RemoveFromLayout"
    "RemoveFromTable" "RemoveImage" "RemoveLayoutObjects" "RemovePath"
    "Rename" "RenameDataFolder" "RenamePICT" "RenamePath"
    "ReorderTraces" "ReplaceText" "ReplaceWave" "ResumeUpdate"
    "Rotate" "Save" "SaveExperiment" "SaveNotebook" "SavePICT"
    "SetAxis" "SetBackground" "SetDashPattern" "SetDataFolder"
    "SetDimLabel" "SetDrawEnv" "SetDrawLayer" "SetFormula"
    "SetIgorMenuMode" "SetIgorOption" "SetMarquee" "SetProcessSleep"
    "SetRandomSeed" "SetScale" "SetVariable" "SetWindow" "ShowInfo"
    "ShowTools" "Silent" "Sleep" "Slider" "Slow" "Smooth"
    "SmoothCustom" "Sort" "SoundInRecord" "SoundInSet"
    "SoundInStartChart" "SoundInStatus" "SoundInStopChart"
    "SphericalInterpolate" "SphericalTriangulate" "Stack"
    "StackWindows" "String" "TabControl" "Tag" "TextBox" "Tile"
    "TileWindows" "TitleBox" "Triangulate3d" "Unwrap" "ValDisplay"
    "Variable" "WaveMeanStdv" "WaveStats" "boundingBall" "fprintf"
    "popup" "printf" "sprintf" "sscanf" "wfprintf")
  "Igor Pro 6 Built-in Operations")

;; Regexp optimized versions of word lists
(defvar igor-procdec-keywords-re
  (regexp-opt igor-procdec-keywords 'words))
(defvar igor-procsub-keywords-re
  (regexp-opt igor-procsub-keywords 'words))
(defvar igor-objrefs-keywords-re
  (regexp-opt igor-objrefs-keywords 'words))
(defvar igor-flowcontrol-keywords-re
  (regexp-opt igor-flowcontrol-keywords 'words))
(defvar igor-hash-keywords-re
  (regexp-opt igor-hash-keywords 'words))
(defvar igor-other-keywords-re
  (regexp-opt igor-other-keywords 'words))

(defconst igor-builtin-functions-re
  (regexp-opt igor-builtin-functions 'words))
(defconst igor-builtin-operations-re
  (regexp-opt igor-builtin-operations 'words))

(defconst igor-defun-start-words
  '("Function" "Macro" "Picture" "Proc"
    "Static" "Structure" "Window")
  "Words that define the beginning of a definition block")

(defconst igor-defun-end-words
  '("End" "EndMacro" "EndStructure")
  "Words that define the end of a definition block")

(defconst igor-blank-re "^[ \t]*$")
(defconst igor-comment-re "^[ \t]*\/\/.*$")

(defconst igor-integer-re
  "\\(?:\\+\\|-\\)?[0-9]+"
  "Integer syntax in Igor")
(defconst igor-number-re
  (concat
   igor-integer-re
   "\\(?:\\.[0-9]+\\)?"                 ; decimal part
   "\\(?:e" igor-integer-re "\\)?")     ; exponent part
   "Number syntax in Igor")
(defconst igor-name-start-re "[a-zA-Z]"
  "Match first character of an identifier name")
(defconst igor-name-re
  (concat
   igor-name-start-re
   "[a-zA-Z0-9_]*")
  "Legal object names in Igor")

(defconst igor-parameter-re
  (concat
   "\\[?[ \t]*" igor-name-re "[ \t]*\\]?")
  "Parameter name with optional brackets")

(defconst igor-parameter-list-re
  (concat
   igor-parameter-re
   "\\(?:[ \t]*\\,[ \t]*" igor-parameter-re "\\)*")
  "Procedure parameter list")

(defconst igor-defun-static-re
  "\\(?:Static[ \t]+\\)")

(defconst igor-defun-start-function
  (concat
   igor-defun-static-re "?"
   "\\(?:Function"
   "\\(\\/\\(?:C\\|D\\|S\\|DF\\|WAVE\\)\\)?\\)"))

(defconst igor-defun-start-picture
  (concat
   igor-defun-static-re "?"
   "\\(?:Picture\\)"))

(defconst igor-defun-start-re
  (concat
   "\\(?:Macro\\|Proc\\|Structure\\|Window" ; non-static start keywords
   "\\|\\(?:" igor-defun-start-function "\\)"
   "\\|\\(?:" igor-defun-start-picture "\\)\\)")
  "Regexp for procedure start. Must define manually to handle
   'Static' prefix cleanly. Function and Picture can have Static
   prefix, but other keywords cannot.")

(defconst igor-defun-end-re
  (concat "^[ \t]*" (regexp-opt igor-defun-end-words 'words)))

(defvar igor-defun-re
  (concat
   "^[ \t]*\\(" igor-defun-start-re "\\)[ \t]+" ; procedure type
   "\\(" igor-name-re "\\)[ \t]*"         ; procedure name
   "\\(([ \t]*"
   "\\(?:" igor-parameter-list-re "\\)?" ; parameter list
   "[ \t]*)\\)"
   "\\([ \t]*:[ \t]*" igor-procsub-keywords-re "[ \t]*\\)?" ; procedure subtype
   )
  "Regexp for definition line of Igor functions/macros/etc.")

;; Syntax Highlighting

;; Syntax Table
(defvar igor-syntax-table
  (let ((st (make-syntax-table)))
    ;; Single-line comments "//"
    (modify-syntax-entry ?/  ". 12" st)
    (modify-syntax-entry ?\n ">" st)
    ;; strings
    (modify-syntax-entry ?\" "\"" st)   ; string literals
    (modify-syntax-entry ?\' "\"" st)   ; literal names
    ;; make underscores part of words
    (modify-syntax-entry ?_  "w" st)
    ;; operators
    (modify-syntax-entry ?$  "." st)
    (modify-syntax-entry ?&  "." st)
    (modify-syntax-entry ?=  "." st)
    (modify-syntax-entry ?^  "." st)
    (modify-syntax-entry ?*  "." st)
    (modify-syntax-entry ?+  "." st)
    (modify-syntax-entry ?-  "." st)
    (modify-syntax-entry ?!  "." st)
    (modify-syntax-entry ?~  "." st)
    (modify-syntax-entry ?<  "." st)
    (modify-syntax-entry ?>  "." st)
    (modify-syntax-entry ?%  "." st)
    (modify-syntax-entry ?|  "." st)
    (modify-syntax-entry ??  "." st)
    (modify-syntax-entry ?:  "." st)
    (modify-syntax-entry ?,  "." st)
    (modify-syntax-entry ?\; "." st)
    ;; parens
    (modify-syntax-entry ?\( "(" st)
    (modify-syntax-entry ?\) ")" st)
    (modify-syntax-entry ?[ "(" st)
    (modify-syntax-entry ?] ")" st)
    st)
  "Syntax table used while in `igor-mode'")

(defvar igor-font-lock-keywords-1
  (eval-when-compile
    (list
     ;; Function names
     (list igor-defun-re
           '(1 font-lock-keyword-face)        ; procedure type
           '(2 font-lock-type-face t t)       ; return type
           '(3 font-lock-function-name-face)  ; procedure name
           '(7 font-lock-keyword-face nil t)  ; procedure subtype
           )
     (cons igor-procdec-keywords-re 'font-lock-keyword-face)
     (cons igor-procsub-keywords-re 'font-lock-keyword-face)
     (cons igor-objrefs-keywords-re 'font-lock-type-face)
     (cons igor-flowcontrol-keywords-re 'font-lock-keyword-face)
     (cons igor-other-keywords-re 'font-lock-type-face)
     (cons igor-builtin-functions-re 'font-lock-builtin-face)
     (cons igor-builtin-operations-re 'font-lock-builtin-face)
     ;; Numbers
     (cons igor-number-re 'font-lock-constant-face)
     (cons igor-hash-keywords-re 'font-lock-preprocessor-face))))

(defvar igor-font-lock-keywords-2
  `(append igor-font-lock-keywords-1
          (,igor-other-keywords-re . font-lock-keyword-face)))

(defvar igor-font-lock-keywords-default
  igor-font-lock-keywords-1)

(defvar igor-font-lock-keywords
  '(igor-font-lock-keywords-default     ; mode default
    igor-font-lock-keywords-1           ; level 1
    igor-font-lock-keywords-2           ; level 2
    ))

(defvar igor-font-lock-defaults
  '(igor-font-lock-keywords-1        ; keyword list
    nil                              ; perform syntactic fontification
    t                                ; ignore case
    nil))                            ; use buffer syntax table

;; Imenu support
(setq igor-imenu-generic-expression
      `(("Procedures" ,igor-defun-re 3)))

;; Indentation
(defvar igor-closeblock-words
  '("End" "EndMacro" "EndStructure"
   "while" "endtry" "endfor" "elseif"
   "endif" "endswitch" "#elif" "#endif")
  "Words that decrease indentation level")

(defvar igor-openblock-words
  '("Function" "Macro" "Menu" "Picture" "Proc" "Static" "Structure" "Window"
    "default" "do" "for" "if" "else" "elseif" "case" "switch"
    "try" "catch" "#if" "#elif" "#ifdef" "#ifndef")
  "Words that increase indentation level")

(defvar igor-closeblock-re
  (concat "^[ \t]*" (regexp-opt igor-closeblock-words 'words)))

(defvar igor-openblock-re
  (concat "^[ \t]*" (regexp-opt igor-openblock-words 'words)))

;; Movement related commands
;; ==================================================

(defun igor-beginning-of-defun()
  "Set the pointer at the beginning of the Function/Macro/etc within which the pointer is located."
  (interactive)
  (re-search-backward igor-defun-start-re))

(defun igor-end-of-defun()
  "Set the pointer at the end of the Function/Macro/etc within which the pointer is located."
  (interactive)
  (re-search-forward igor-defun-end-re))

(defun igor-mark-defun()
  "Set the region pointer around Function/Macro/etc within which the pointer is located."
  (interactive)
  (beginning-of-line)
  (igor-end-of-defun)
  (set-mark (point))
  (igor-beginning-of-defun))


;; Indentation related commands
;; ==================================================

(defun igor-previous-line-of-code()
  "Set point on previous line of code, skipping any blank or comment lines."
  (interactive)
  (if (not (bobp))
      (forward-line -1))        ; previous-line depends on goal column
  (while (and (not (bobp))
              (or (looking-at igor-blank-re)
                  (looking-at igor-comment-re)))
    (forward-line -1)))

(defun igor-next-line-of-code()
  "Set point on next line of code, skipping any blank or comment lines."
  (interactive)
  (if (null (eobp))
      (forward-line 1))        ; next-line depends on goal column
  (while (and (null (eobp))
              (looking-at igor-comment-re))
    (forward-line 1)))

(defun igor-find-predicate-matching-stmt (open-p close-p)
  "Find opening statement statisfying OPEN-P predicate for which
  matching closing statement statisfies CLOSE-P predicate.

  Point is set on line statifying OPEN-P predicate, with ignoring
  any line satifying OPEN-P but for which a matching line
  statifying CLOSE-P was visited before during this search."
  ;; Searching backwards
  (let ((level 0))
    (while (and (>= level 0) (not (bobp)))
      (igor-previous-line-of-code)
      (cond ((funcall close-p)
             (setq level (+ level 1)))
            ((funcall open-p)
             (setq level (- level 1)))))))

(defun igor-find-matching-stmt (open-re close-re)
  "Same as function `igor-find-predicate-matching-stmt' except
  that regexps OPEN-RE CLOSE-RE are supplied instead of
  predicate, equivalent predicate being to be looking at those
  regexps."
  (igor-find-predicate-matching-stmt
   (lambda () (looking-at open-re))
   (lambda () (looking-at close-re))))

(defun igor-find-first-predicate-matching-stmt (open-p sub-p)
  "Find opening statement statisfying OPEN-P predicate for which
  a potentially repeating sub-statement satisfying SUB-P
  predicate.

  Point is set on first previous line satisfying OPEN-P
  predicate.  It does not account for other instances of SUB-P
  found before encountering an OPEN-P match, as occurs in
  `igor-find-predicate-matching-stmt'.  The canonical use case is
  for multiple `case' statements under a `switch' stmt."
  ;; Searching backwards
  (let (found)
    (while (and (not found) (not (bobp)))
      (igor-previous-line-of-code)
      (if (funcall open-p)
          (setq found t)))))

(defun igor-find-first-matching-stmt (open-re sub-re)
  "Same as function `igor-find-first-predicate-matching-stmt'
  except that regexps OPEN-RE and SUB-RE are supplied
  instead of predicates"
  (igor-find-first-predicate-matching-stmt
   (lambda () (looking-at open-re))
   (lambda () (looking-at sub-re))))

(defun igor-convert-pairs-str-to-re (inlist)
  "Convert pairs of strings to pairs of optimized regexps"
  (let (regexp-list)
    (dolist (curr (reverse inlist) regexp-list)
      (push (list
             (igor-wrap-re-startline
              (regexp-opt (list (car curr)) 'words))
             (igor-wrap-re-startline
              (regexp-opt (cdr curr) 'words)))
            regexp-list))))

(defun igor-flip-pairs (inlist)
  "Flip direction of start-end pairs"
  (let (newlist)
    (dolist (pair (reverse inlist) newlist)
      (dolist (endkey (cdr pair))
        (if (assoc endkey newlist)
            (push (car pair) (cdr (assoc endkey newlist)))
          (push (list endkey (car pair)) newlist))))))

(defun igor-build-match-list (inlist)
  "Return an indentation matching list

INLIST must be a list of cons cells which hold a start keyword in
car and one or more matching end keywords in cdr.

The match list format transforms this list into a mapping with
end keywords as the keys. The value of each cell is a list of
cells holding the matching start keyword in car and all valid end
keywords for that start keyword. This is structure is necessary
because an ending keyword may have multiple start keywords, and
each valid start keyword may have a different set of valid end
keywords."
  (let (newlist)
    (dolist (pair inlist newlist)
      (dolist (endkey (cdr pair))
        (let ((match-cell (assoc endkey newlist)))
          (if match-cell
              (push pair (cadr match-cell))
            ;; create an empty list and add a cons cell to it should
            ;; be able to do this in one-line, but elisp doesn't like
            ;; it
            (progn
              (let ((new-cell (cons endkey '())))
                (push (make-list 1 pair) (cdr new-cell))
                (push new-cell newlist)))))))))

(igor-build-match-list igor-indent-same-pairs-forward)

(defun igor-append-pairs (curlist inlist)
  "Adds the pairs in INLIST to the CURLIST, adding the cdr of the
list to a pre-exisiting pair if it already exists"
  (let ((newlist (copy-tree curlist t)))
    (dolist (new-pair inlist newlist)
      (let ((match-cell
             (assoc (car new-pair) newlist)))
        (if match-cell
            (dolist (new-elt (cdr new-pair))
              (if (not (rassoc new-elt match-cell))
                  (push new-elt (cdr match-cell))))
          (push new-pair newlist))))))

;;; Indentation pairs
;; When a keyword is encountered that defines a block, it may
;;  * start a construct (following lines are indented)
;;  * end a construct (unindent to start level)
;;  * start a new section of the construct (a mid-level keyword), which may:
;;     * unindent to start and be used multiple times (e.g., if-elseif)
;;     * unindent to start and be used only once (e.g., if-else)
;;     * indent from start and be used multiple times (e.g., switch-case)
;;     * indent from start and be used only once (e.g., switch-default)
;;  * no keyword is found (indent as previous line)
(defconst igor-start-end-pairs
  '(("Function" "End")
    ("Static Function" "End")
    ("Macro" "End" "EndMacro")
    ("Menu" "End")
    ("Picture" "End" "EndMacro")
    ("Static Picture" "End" "EndMacro")
    ("Proc" "End" "EndMacro")
    ("Structure" "End" "EndStructure")
    ("Window" "End" "EndMacro")
    ("if" "endif")
    ("for" "endfor")
    ("do" "while")
    ("switch" "endswitch")
    ("strswitch" "endswitch")
    ("try" "endtry")
    ("#if" "#endif")
    ("#ifdef" "#endif")
    ("#ifndef" "#endif"))
  "List of cons cells of start and end keywords for indentation
  blocks. cdr holds all valid end keywords of the car keyword.")

(defconst igor-start-middle-pairs
  '(("if" "else")
    ("try" "catch"))
  "List of cons cells of start and single-use mid-level keywords
  for same-level indentation.")

(defconst igor-start-middle-many-pairs
  '(("if" "elseif")
    ("#if" "#elif"))
  "List of cons cells of start and multi-use mid-level keywords
  for same-level indentation.")

(defconst igor-start-middle-inc-pairs
  '(("switch" "default")
    ("strswitch" "default"))
  "List of cons cells of start and single-use mid-level keywords
  for increased-level indentation.")

(defconst igor-start-middle-many-inc-pairs
  '(("switch" "case")
    ("strswitch" "case"))
  "List of cons cells of start and multi-use mid-level keywords
  for increased-level indentation.")

(defconst igor-indent-same-pairs-forward
  (igor-append-pairs
   igor-start-end-pairs igor-start-middle-pairs)
  "List of cons cells of signle-use same-level start and end
  keywords")

(defconst igor-indent-same-pairs
  (igor-flip-pairs
   igor-indent-same-pairs-forward)
  "List of cons cells of single-use same-level end and start
  keywords.")

(defconst igor-indent-same-many-pairs
  (igor-flip-pairs
   (append igor-start-middle-many-pairs))
  "List of cons cells of multi-use same-level end and start
  keywords.")

(defconst igor-indent-increase-pairs
  (igor-flip-pairs
   (append igor-start-middle-inc-pairs))
  "List of cons cells of single-use increased-level end and start
  keywords.")

(defconst igor-indent-increase-many-pairs
  (igor-flip-pairs
   (append igor-start-middle-many-inc-pairs))
  "List of cons cells of multi-use increased-level end and start
  keywords.")

(defconst igor-indent-same-pairs-forward-re
  (igor-convert-pairs-str-to-re igor-indent-same-pairs-forward))

(defconst igor-indent-same-pairs-re
  (igor-convert-pairs-str-to-re igor-indent-same-pairs))

(defconst igor-indent-same-many-pairs-re
  (igor-convert-pairs-str-to-re igor-indent-same-many-pairs))

(defconst igor-indent-increase-pairs-re
  (igor-convert-pairs-str-to-re igor-indent-increase-pairs))

(defconst igor-indent-increase-many-pairs-re
  (igor-convert-pairs-str-to-re igor-indent-increase-many-pairs))

(defconst igor-indent-same-keys-re
  (igor-wrap-re-startline
   (regexp-opt
    (sort (mapcar 'car igor-indent-same-pairs) 'string<) 'words)))
(defconst igor-indent-same-many-keys-re
  (igor-wrap-re-startline
   (regexp-opt
    (sort (mapcar 'car igor-indent-same-many-pairs) 'string<) 'words)))
(defconst igor-indent-increase-keys-re
  (igor-wrap-re-startline
   (regexp-opt
    (sort (mapcar 'car igor-indent-increase-pairs) 'string<) 'words)))
(defconst igor-indent-increase-many-keys-re
  (igor-wrap-re-startline
   (regexp-opt
    (sort (mapcar 'car igor-indent-increase-many-pairs) 'string<) 'words)))

(defun igor-find-indent-match (inlist)
  "Return indent count for the matched regexp pair from
  inlist. Assumes the open-re is in cdr and close-re is in
  car (flipped pairs, see `igor-flip-pairs').  Finds the first
  unclosed occurence of open-re."
  (let ((elt (car inlist)))
    (if (looking-at (car elt))
        (progn
          (igor-find-matching-stmt (cadr elt) (car elt))
          (current-indentation))
      (igor-find-indent-match (cdr inlist)))))

(defun igor-find-first-indent-match (inlist)
  "Return indent count for the matched regexp pair from
  inlist. Assumes the open-re is in cdr and close-re is
  in car (flipped pairs, see `igor-flip-pairs').  Finds the first
  occurence of open-re."
  (let ((elt (car inlist)))
    (if (looking-at (car elt))
        (progn
          (igor-find-first-matching-stmt (cadr elt) (car elt))
          (current-indentation))
      (igor-find-first-indent-match (cdr inlist)))))

(defun igor-calculate-indent ()
  "Return indent count for the line of code containing pointer."
  (let ((original-point (point)))
    (save-excursion
      (beginning-of-line)
      (cond
       ;; If first line, no indentation
       ((bobp)
        0)

       ((looking-at "^[ \t]*\\<\\(else\\)\\>")
        (progn
          (igor-find-matching-stmt "^[ \t]*\\<\\(if\\)\\>"
                                   "^[ \t]*\\<\\(else\\|elseif\\|endif\\)\\>")
          (current-indentation)))

       ;; Statements that match start keyword indent
       ((looking-at igor-indent-same-keys-re) ; single-use words
        (igor-find-indent-match
         igor-indent-same-pairs-re))

       ((looking-at igor-indent-same-many-keys-re) ; multi-use
        (igor-find-first-indent-match
         igor-indent-same-many-pairs-re))


       ;; Keywords that increase start keyword indent
       ((looking-at igor-indent-increase-keys-re) ; single-use words
        (+ (igor-find-indent-match
            igor-indent-increase-pairs-re)
           igor-tab-width))

       ((looking-at igor-indent-increase-many-keys-re) ; multi-use
        (+ (igor-find-first-indent-match
            igor-indent-increase-many-pairs-re)
           igor-tab-width))

       ;; Cases depending on previous line indent
       (t
        (igor-previous-line-of-code)
        ;; Block open stmts increase next line indent
        (if (looking-at igor-openblock-re)
            (+ (current-indentation) igor-tab-width)
          ;; By default, just copy indent from prev line
          (current-indentation)))))))

(defun igor-indent-to-column (col)
  "Indent line of code containing pointer up to column COL."
  (let* ((bol (save-excursion
                (beginning-of-line)
                (point)))
         (point-in-whitespace
          (<= (point) (+ bol (current-indentation))))
         (blank-line-p
          (save-excursion
            (beginning-of-line)
            (looking-at igor-blank-re))))

    (cond ((/= col (current-indentation))
           (save-excursion
             (beginning-of-line)
             (back-to-indentation)
             (delete-region bol (point))
             (indent-to col))))

    ;; If point was in the whitespace, move back-to-indentation.
    (cond (blank-line-p
           (end-of-line))
          (point-in-whitespace
           (back-to-indentation)))))

(defun igor-indent-line ()
  "Indent current line for IgorPro."
  (interactive)
  (igor-indent-to-column (igor-calculate-indent)))

;;; Autoload/unload
(require 'igor-exec)

(defvar igor-reload-include-list ()
  "List to hold names of include files to load after saving")

(defun igor-unload-igor-procedure ()
  (if (igor-is-should-autoload)
      (let ((curr-include
             (igor-curr-filename-no-ext)))
        (if (igor-exec-is-proc-included curr-include)
            (progn
              (push curr-include igor-reload-include-list)
              (igor-exec-execute
               (igor-exec-cmd-close-procedure (igor-curr-filename))
               (igor-exec-cmd-delete-include curr-include)
               (igor-exec-cmd-compileprocedures))
              (igor-wait-for-procs-compiled))
          nil))
    nil))

(defun igor-reload-igor-procedure ()
  (if (igor-is-should-autoload)
      (let ((curr-include
             (igor-curr-filename-no-ext)))
        (if (igor-is-proc-need-reload curr-include)
            (progn
              (delete curr-include igor-reload-include-list)
              (igor-exec-execute
               (igor-exec-cmd-insert-include curr-include)
               (igor-exec-cmd-compileprocedures)))
          nil))
    nil))

(defun igor-is-should-autoload ()
  "Returns t if autoloading is appropriate, nil if not"
  (and
   igor-use-autoreload
   (equal "ipf" (file-name-extension buffer-file-name))
   (igor-exec-is-igor-running)))

(defun igor-is-proc-need-reload (include-name)
  "Returns t if INCLUDE-NAME needs to be loaded back into Igor, nil if not"
  (member include-name igor-reload-include-list))

(defun igor-wait-for-procs-compiled ()
  (let ((wait-time 0))
    (progn
      (while (and (< wait-time 10)
                 (not (equal (igor-exec-is-procs-compiled) t)))
        (progn
          (setq wait-time (+ wait-time 0.5))
          (sleep-for 0.5))))))

(defun igor-curr-filename-no-ext ()
  "Returns the current buffer's filename without its extension"
  (file-name-nondirectory
   (file-name-sans-extension
    (buffer-file-name))))
(defun igor-curr-filename ()
  "Returns the current buffer's filename (by itself)"
  (file-name-nondirectory
   (buffer-file-name)))

(add-hook 'igor-mode-hook
          '(lambda ()
             (add-hook 'before-save-hook
                       'igor-unload-igor-procedure nil t)))
(add-hook 'igor-mode-hook
          '(lambda ()
             (add-hook 'after-save-hook
                       'igor-reload-igor-procedure nil t)))

;; Clear memory of keyword lists (which are now saved in regexps)
(setq igor-procdec-keywords nil)
(setq igor-procsub-keywords nil)
(setq igor-objrefs-keywords nil)
(setq igor-flowcontrol-keywords nil)
(setq igor-hash-keywords nil)
(setq igor-other-keywords nil)
(setq igor-builtin-functions nil)
(setq igor-builtin-operations nil)

;; Define this mode
(define-derived-mode igor-mode fundamental-mode "Igor"
  "Major mode for editing IgorPro procedure files."
  (set (make-local-variable 'font-lock-defaults) igor-font-lock-defaults)
  (set-syntax-table igor-syntax-table)
  (set (make-local-variable 'indent-line-function) 'igor-indent-line)
  (set (make-local-variable 'tab-width) igor-tab-width)
  (set (make-local-variable 'comment-start) "// ")
  (set (make-local-variable 'comment-end) "")
  (setq imenu-generic-expression igor-imenu-generic-expression)
  (imenu-add-to-menubar "Igor"))

(provide 'igor-mode)
;;; igor-mode.el ends here