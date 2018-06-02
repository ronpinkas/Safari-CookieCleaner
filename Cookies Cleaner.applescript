(*
   Author: Ron Pinkas
  
   You are free to use this code in any way permitable by the GNU General Public License V3.0 
*)

on main()
	set debugLog to false
	
	# NON GRIDY so use full name INCLUDING .com etc.!
	set whiteList to {"amazon.com", Â
		"ebay.com", Â
		"github.com", "google.com", "googleusercontent.com", Â
		"instagram.com", Â
		"netflix.com", Â
		"paypal.com", Â
		"twitter.com", Â
		"visualstudio.com", Â
		"whatsapp.com"}
	
	# GRIDY - so be careful as ANY domain name CONTAINING any of these tokens (but NOT WHITE listed) will be considered junk!
	# IF FIRST Element is "*" then the junkList will be ignored and ALL EXCEPT whiteList will be deleted!
	set junkList to {"*", ".co.", "addthis", "adobe", "affirm", "akc", "allure", "akamai", "azureedge", Â
		"barron", "beaver", "bam-x", "bing", "bkrtx", "blue", "bold", "boot", "bounce", "btt", "b-cdn", Â
		"cdn", "chartbeat", "chimp", "click", "cloudflare", "cloudfront", "cnbc", "cohesion", "cookie", "count", "coust", "crazy", "createjs", "criteo", "crsspxl", "crwd", Â
		"dazz", "demdex", "dental", "desk", "digitech", "disqus", "docashop", Â
		"exelator", "expose", "ggpht", "facebook", "fbcdn", "google-analytics", "googleadservices", "googletag", "googleusercontent", "gravatar", "gstatic", Â
		"home", "imgur", "jeeng", "link", "local", "mac", "networks", "newrelic", "omny", "opentok", "optimizer", "parsely", "petametric", "pir.fm", "porn","quantserve", Â
		"reddit", "resources", "score", "sekindo", "sstatic", "stack", "taboola", "track", "truspilot", "twimg", "user", "visistat", "ytimg"}
	
	set homePath to (path to home folder)
	set databasesPath to alias ((homePath as text) & "Library:Safari:Databases")
	set indexedPath to alias ((databasesPath as text) & "___IndexedDB")
	
	tell application "System Events"
		tell process "Safari"
			activate
			set frontmost to true
			
			set myMenu to menu "Safari" of menu bar item "Safari" of menu bar 1
			click menu item "PreferencesÉ" of myMenu
			
			repeat while not (exists window 1)
				delay 0.01
			end repeat
			set windowPrefernces to window 1
			
			tell windowPrefernces
				click button "Privacy" of toolbar 1
				# WAIT till opened.
				repeat while not (exists button "Manage Website DataÉ" of group 1 of group 1)
					delay 0.01
				end repeat
				
				click button "Manage Website DataÉ" of group 1 of group 1
				# WAIT till opened.
				repeat while not (exists table 1 of scroll area 1 of sheet 1)
					delay 0.01
				end repeat
				
				set myTable to table 1 of scroll area 1 of sheet 1
				set searchField to text field 1 of sheet 1
				
				-- Allow ALL except WHITE list to be considered JUNK by setting FIRST Specifier to "*"! 
				try
					if (count of whiteList) > 0 and first item of junkList is equal to "*" then
						# will neveer get here if whiteList is undefined or empty!
						# Simulate an ALL is JUNK mode - ignoring the rest of junkList.
						set junkList to {""}
					end if
				end try
				
				# SEARCH MATCHES for ALL Specifiers of junkList
				repeat with junk in junkList
					if junk is equal to "" and junk is not equal to first item of junkList then
						display notification "Invalid junk specifier \"\""
						set junk to "*empty specifier ignored*"
					end if
					
					select searchField
					set value of searchField to junk
					
					-- WAIT UNTIL Search terminates, with either some rows OR "No Saved Website Data" is displayed!
					set noJunk to false
					repeat
						delay 0.01
						
						if (count of (rows of myTable)) > 0 then
							--display notification "Found prospective junk: '" & junk & "'"
							exit repeat
						else
							try
								set uiChildren to entire contents of sheet 1
								
								repeat with itemIterator in uiChildren
									if class of itemIterator is static text and value of itemIterator contains "No Saved Website Data" then
										set noJunk to true
										exit repeat
									end if
								end repeat
								
								if noJunk then
									--display notification "No junk found for: " & junk
									exit repeat
								end if
							end try
						end if
					end repeat
					-- END WAIT					
					
					set junkRows to count of (rows of myTable)
					set whiteListed to false
					set rowSite to ""
					set rowIndex to 1
					
					#Reset Scroll bar to TOP, incase Windos was alreasdy opened, and scrolled by User
					set value of scroll bar 1 of scroll area 1 of sheet 1 to 0
					
					# PROCESS ALL Lines MATCHING junk specifier
					repeat while junkRows ³ rowIndex
						try
							set selectedRow to row rowIndex of myTable
							select selectedRow
							set rowSite to description of first UI element of selectedRow
							set domainName to first item of my textTokens(rowSite, space)
							
							if debugLog then
								log "-------- TOP"
								log "Cookie: '" & rowSite & "'"
								log "Domain: '" & domainName & "'"
								log "rowIndes: " & rowIndex as text
								log "junkRows: " & junkRows as text
								log "count of rows: " & (count of (rows of myTable)) as text
							end if
							
							-- AppleScript indexing is 1 based BUT item 0 maps to 1 so it can nbe very confusing!
							-- SCROLL so selected row (as well as at least the prior and next rows) are in the VISIBLE Scroll port.
							repeat while (count of value of attribute "AXVisibleChildren" of row (my min(rowIndex + 1, junkRows)) of myTable) = 0
								--tell scroll area 1 of sheet 1 to perform action "AXScrollUpByPage"
								click button 1 of scroll bar 1 of scroll area 1 of sheet 1
								delay 0.01
							end repeat
							repeat while (count of value of attribute "AXVisibleChildren" of row (my max(rowIndex - 1, 1)) of myTable) = 0
								--tell scroll area 1 of sheet 1 to perform action "AXScrollDownByPage"
								click button 2 of scroll bar 1 of scroll area 1 of sheet 1
								delay 0.01
							end repeat
							-- END SCROLL
							
							-- SEARCH whiteList 
							set whiteListed to false
							repeat with whiteSite in whiteList
								--log "White: '" & whiteSite & "'"
								
								# whiteSite is a REFERENCE which must be DEreferenced to be correctly compared!
								--log "Equals: " & (domainName is equal to whiteSite) as text
								--log "Equals: " & (domainName is equal to whiteSite as text) as text
								
								# First option is a gridier option which may match more thann intennded but may be desired by some. 
								--if rowSite contains whiteSite then
								if domainName is equal to whiteSite as text then
									set whiteListed to true
									exit repeat
								end if
							end repeat
							-- END SEARCH whiteList
							
							if whiteListed then
								log "White: " & rowSite
								set rowIndex to rowIndex + 1
							else
								log "Delete: " & rowSite
								
								# DATABASE first
								if rowSite contains "Databases" then
									-- FIND & DELETE DATABASE file
									log domainName & ": Has Databases!"
									
									# Avoiding GRIDINESS of conatins 
									set myFiles to (files of application "System Events"'s folder (databasesPath as text) where (name contains ("." & domainName)) or name contains ("_" & domainName))
									set myFiles to myFiles & (folders of application "System Events"'s folder (indexedPath as text) where (name contains ("." & domainName)) or name contains ("_" & domainName))
									
									repeat with theFile in myFiles
										log "Trash: " & name of theFile
										move theFile to application "System Events"'s trash
										--end if
									end repeat
									-- END FIND & DELETE
								end if
								-- END DATABASE
								
								# DELETE!
								set repeatCount to 0
								repeat until (repeatCount > 10) or (junkRows > (count of (rows of myTable)))
									set repeatCount to repeatCount + 1
									
									# Because row may be last row and might have been deleted just after above until was evaluated.
									try
										# Row must be SELECTED (even if was) to enable the Remove button!
										repeat until selected of selectedRow
											select selectedRow
											delay 0.01
										end repeat
										click button "Remove" of sheet 1
										delay 0.1
									end try
								end repeat
								
								if junkRows = (count of (rows of myTable)) then
									log "Failed deleting: " & rowSite
								end if
								-- END DELETE
							end if
						on error msg number n from f to t partial result p
							--log "*** ERROR! " & msg
							error msg number n from f to t partial result p
						end try
						
						# Here instead of just after DELETE because it might also change outside of our control!
						set junkRows to count of (rows of myTable)
						
						if debugLog then
							log "-------- BOTTOM"
							log "Cookie: '" & rowSite & "'"
							log "Domain: '" & domainName & "'"
							log "rowIndes: " & rowIndex as text
							log "junkRows: " & junkRows as text
							log "count of rows: " & (count of (rows of myTable)) as text
						end if
					end repeat #while junkRows > rowIndex	
					-- END PROCESS ALL Lines MATCHING
				end repeat #with junk in junkList
				-- ENND SEARCH
				
				click button "Done" of sheet 1
				
				# Don't like this style.
				--keystroke "w" using command down
				
				# This is hard coded but works
				--click button 1
				
				# For some odd reason both these stryles fails :(
				--click (button where role description is "close button")
				--set closeButton to first item of buttons where role description = "close button"
				--click closeButton
				
				# Resorting to manual iteration.
				repeat with theBtn in buttons
					try
						--log "'" & role description of theBtn & "'"
						if role description of theBtn = "close button" then
							click theBtn
							exit repeat
						end if
					end try
				end repeat
			end tell
		end tell
	end tell
end main

on textTokens(textToParse, parseDelimiters)
	set listTokens to missing value
	set asTID to AppleScript's text item delimiters
	
	try
		set AppleScript's text item delimiters to parseDelimiters
		set listTokens to text items of textToParse
	end try
	
	set AppleScript's text item delimiters to asTID
	return listTokens
end textTokens

on min(n1, n2)
	if n1 ² n2 then
		return n1
	end if
	
	return n2
end min

on max(n1, n2)
	if n1 ³ n2 then
		return n1
	end if
	
	return n2
end max

on run {}
	main()
end run