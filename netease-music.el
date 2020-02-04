;;; netease-music-random.el --- listen netease music randomly

;; Copyright (C) 2020  silentCoding
;; Version: 1.0
;; URL: https://github.com/
;; Package-Requires: ((names "0.5") (emacs "25"))
;; Author: silentCoding <7213182@163.com>
;; Keywords: Chinese music netease random

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library was developed for listening music from Netease cloud randomlyin Emacs.
;; The idea and API is inspired by <https://ziliao6.com/fm/>.
;; The program is inspired by <https://github.com/nicehiro/netease-music>, and the code is modified from this project.  
;; netease-music-play-song Play a song randomly.
;; netease-music-toggle Pause or resume the current song.
;; netease-music-play-next Change another song.
;; You can not choose anything except listen or not listen.

;;; Code:

(require 'json)
(require 'url)
(require 'names)

;;;###autoload
(define-namespace netease-music-

(defcustom player "mplayer"
  "Netease music player.  Default player is mplayer."
  :type 'string)

(defvar status ""
  "Netease music player status.")

(defvar process nil
  "The process of netease music player.")

(defun kill-process ()
  "Kill current playing process."
  (when (and process
             (process-live-p process))
    (delete-process process)
    (setq process nil)))

(defun proc-sentinel (proc change)
  "Netease music sentinel for PROC with CHANGE."
  (when (string-match "\\(finished\\|Exiting\\)" change)
    (play-next)))

(defun request ()
  "Request the music resource from netease music. Return json by requesting the url."
  (let (json)
    (with-current-buffer (url-retrieve-synchronously
                          "https://api.uomg.com/api/rand.music?sort=%E7%83%AD%E6%AD%8C%E6%A6%9C&format=json")
      (set-buffer-multibyte t)
      (goto-char (point-min))
      (re-search-forward "^$" nil 'move)
      (setq json (json-read-from-string
                  (buffer-substring-no-properties (point) (point-max))))
      (kill-buffer (current-buffer)))
    json))

(defun process-live-p (proc)
  "Check netease music PROC is alive."
  (memq (process-status proc)
        '(run open listen connect stop)))

(defun play ()
  "Play a song"
  (let ((song-real-url (cdr (assoc 'url (cdr (assoc 'data (request)))))))
    (unless (and process
                 (process-live-p process))
      (setq process
            (start-process "netease-music-proc"
                           nil
                           player
                           (if (string-match player "mplayer")
                               "-slave"
                             "")
		           "-prefer-ipv4"
                           song-real-url))
      (set-process-sentinel process 'netease-music-proc-sentinel))))

:autoload
(defun play-song ()
  "Play a song. Make a meaningful function name."
  (interactive)
  (if (and process
           (process-live-p process))
      (kill-process))
  (play))

:autoload
(defun play-next ()
  "Play another song. Make a meanmingful function name."
  (interactive)
  (play-song))

:autoload
(defun toggle ()
  "Pause or replay the song."
  (interactive)
  (if (string-match status "playing")
      (progn
	(setq status "paused")
        (process-send-string process "pause\n"))
    (if (string-match status "paused")
        (progn
	  (setq status "playing")
          (process-send-string process "pause\n")))))

) ; end of define-namespace

(provide 'netease-music-random)
;;; netease-music-random.el ends here


