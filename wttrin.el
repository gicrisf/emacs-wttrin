;;; wttrin.el --- Emacs frontend for weather web service wttr.in
;; Copyright (C) 2016 Carl X. Su

;; Author: Carl X. Su <bcbcarl@gmail.com>
;;         ono hiroko (kuanyui) <azazabc123@gmail.com>
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.4") (xterm-color "1.0"))
;; Keywords: comm, weather, wttrin
;; URL: https://github.com/bcbcarl/emacs-wttrin

;;; Commentary:

;; Provides the weather information from wttr.in based on your query condition.

;;; Code:

(require 'url)
(require 'xterm-color)
(require 'emojify)

(defgroup wttrin nil
  "Emacs frontend for weather web service wttr.in."
  :prefix "wttrin-"
  :group 'comm)

(defcustom wttrin-default-cities '("Taipei" "Keelung" "Taichung" "Tainan")
  "Specify default cities list for quick completion."
  :group 'wttrin
  :type 'list)

(defcustom wttrin-default-accept-language '("Accept-Language" . "en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4")
  "Specify default HTTP request Header for Accept-Language."
  :group 'wttrin
  :type '(list)
  )

(defun wttrin-fetch (query format)
  "Get the weather information based on your QUERY and FORMAT."
  (let ((url-user-agent "curl"))
    (add-to-list 'url-request-extra-headers wttrin-default-accept-language)
    (with-current-buffer
        (url-retrieve-synchronously
         (concat "http://wttr.in/" query format)
         (lambda (status) (switch-to-buffer (current-buffer))))
      (decode-coding-string (buffer-string) 'utf-8))))

;; Keeping this for the moment
(defun wttrin-fetch-raw-string (query)
  "Get the weather information based on your QUERY."
  (let ((url-user-agent "curl"))
    (add-to-list 'url-request-extra-headers wttrin-default-accept-language)
    (with-current-buffer
        (url-retrieve-synchronously
         (concat "http://wttr.in/" query "?A")
         (lambda (status) (switch-to-buffer (current-buffer))))
      (decode-coding-string (buffer-string) 'utf-8))))

(defun wttrin-exit ()
  "Exit from wttrin."
  (interactive)
  (quit-window t))

(defun wttrin-query-large (city-name)
  "Query weather of CITY-NAME via wttrin and display the result in new buffer."
  (let ((raw-string (wttrin-fetch city-name "?A")))
    (if (string-match "ERROR" raw-string)
        (message "Cannot get weather data. Maybe you inputed a wrong city name?")
      (let ((buffer (get-buffer-create (format "*wttr.in - %s*" city-name))))
        (switch-to-buffer buffer)
        (setq buffer-read-only nil)
        (erase-buffer)
        (insert (xterm-color-filter raw-string))
        (goto-char (point-min))
        (re-search-forward "^$")
        (delete-region (point-min) (1+ (point)))
        (use-local-map (make-sparse-keymap))
        (local-set-key "q" 'wttrin-exit)
        (local-set-key "g" 'wttrin)
        (setq buffer-read-only t)))))

;; TODO make a single query func and externalize the work of text manipulation
(defun wttrin-query-one-line (city-name)
  "Get CITY-NAME weather via wttrin, display a one-line result in the minibuffer."
  (let ((raw-string (wttrin-fetch city-name "?format=3")))
    (if (string-match "ERROR" raw-string)
        (message "Cannot get weather data. Maybe you inputed a wrong city name?")
      (with-temp-buffer (let ((buffer (get-buffer-create "temp-buff")))
           (setq buffer-read-only nil)
           (erase-buffer)
           (insert raw-string)
           ;; Delete header
           (goto-char (point-min))
           (re-search-forward "^$")
           (delete-region (point-min) (1+ (point)))
           ;; Print in minibuffer
           (message
            (emojify-string
             (buffer-substring (point-min) (line-end-position)))))))))

;;;###autoload
(defun wttrin (city)
  "Display weather information for CITY."
  (interactive
   (list
    (completing-read "City name: " wttrin-default-cities nil nil
                     (when (= (length wttrin-default-cities) 1)
                       (car wttrin-default-cities)))))
  (wttrin-query-large city))

(defun wttrin-one-line (city)
  "Display weather information for CITY."
  (interactive
   (list
    (completing-read "City name: " wttrin-default-cities nil nil
                     (when (= (length wttrin-default-cities) 1)
                       (car wttrin-default-cities)))))
  (wttrin-query-one-line city))

(provide 'wttrin)

;;; wttrin.el ends here
