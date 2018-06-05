(*
   Author: Ron Pinkas
  
   You are free to use this code in any way permitable by the GNU General Public License V3.0 
*)

on main()
	set debugLog to false
	
	# Item starting with "*" will match domain names ENDING with its subssequent text 
	# Item endiding with "*" will match domain names BEGINING with its preceding text
	# Items starting and ending with "*" will match domain names CONTAINING its enclosed text	
	# Otherwise NON GRIDY so use full name INCLUDING .com etc.!
	set whiteList to {"amazon.com", Â
		"ebay.com", Â
		"facebook.com", "facebook.net", Â
		"github.com", "*.githubusercontent.com", Â
		"google.com", "google-analytics.com", "*.googleapis.com", "googleusercontent.com", "gstatic.com", Â
		"instagram.com", "cdninstagram.com", Â
		"netflix.com", Â
		"paypal.com", Â
		"twitter.com", "twimg.com", Â
		"visualstudio.com", Â
		"whatsapp.*", Â
		"youtube.com"}
	
	# Items in this list will be fed AS-IS to Safari's cookie search field, which is GRIDY, i.e
	# it uses CONTAINS logic to search for matches - so be careful or better yet
	# protect valuable domains using the above whiteList! 
	# IF FIRST Element is "*" then the junkList will be ignored and ALL EXCEPT whiteList will be deleted!
	set junkList to {"*", ".co.", "addthis", "adobe", "affirm", "akc", "allure", "akamai", "azureedge", Â
		"barron", "beaver", "bam-x", "bing", "bkrtx", "blue", "bold", "boot", "bounce", "btt", "b-cdn", Â
		"cdn", "chartbeat", "chimp", "click", "cloudflare", "cloudfront", "cnbc", "cohesion", "cookie", "count", "coust", "crazy", "createjs", "criteo", "crsspxl", "crwd", Â
		"dazz", "demdex", "dental", "desk", "digitech", "disqus", "docashop", Â
		"exelator", "expose", "ggpht", "facebook", "fbcdn", "google-analytics", "googleadservices", "googletag", "googleusercontent", "gravatar", "gstatic", Â
		"home", "imgur", "jeeng", "link", "local", "mac", "networks", "newrelic", "omny", "opentok", "optimizer", "parsely", "petametric", "pir.fm", "porn", "quantserve", Â
		"reddit", "resources", "score", "sekindo", "sstatic", "stack", "taboola", "track", "truspilot", "twimg", "user", "visistat", "ytimg"}
	
	set homePath to (path to home folder)
	set databasesPath to alias ((homePath as text) & "Library:Safari:Databases")
	set indexedDBPath to alias ((databasesPath as text) & "___IndexedDB")
	
	tell application "Safari" to activate
	
	tell application "System Events"
		tell process "Safari"
			set frontmost to true
			
			set myMenu to menu "Safari" of menu bar item "Safari" of menu bar 1
			click menu item "PreferencesÉ" of myMenu
			# WAIT till opened.
			repeat until (exists button "Privacy" of toolbar 1) of window 1
				delay 0.01
			end repeat
			
			set windowPreferences to window 1
			
			tell windowPreferences
				click button "Privacy" of toolbar 1
				# WAIT till opened.
				repeat until (exists button "Manage Website DataÉ" of group 1 of group 1)
					delay 0.01
				end repeat
				
				click button "Manage Website DataÉ" of group 1 of group 1
				# WAIT till opened.
				repeat until (exists table 1 of scroll area 1 of sheet 1)
					delay 0.01
				end repeat
				
				set myTable to table 1 of scroll area 1 of sheet 1
				set searchField to text field 1 of sheet 1
				
				-- Allow ALL except WHITE list to be considered JUNK by setting FIRST Specifier to "*"! 
				try
					if (count of whiteList) > 0 and first item of junkList is equal to "*" then
						# will never get here if whiteList is undefined or empty!
						# Simulate an ALL is JUNK mode - ignoring the rest of junkList.
						set junkList to {""}
					end if
				end try
				
				# SEARCH MATCHES for ALL Specifiers of junkList
				repeat with theJunkSpecifier in junkList
					if theJunkSpecifier is equal to "" and theJunkSpecifier is not equal to first item of junkList then
						display notification "Invalid junk specifier \"\""
						set theJunkSpecifier to "*empty specifier ignored*"
					end if
					
					select searchField
					set value of searchField to theJunkSpecifier
					
					-- WAIT UNTIL Search finalizes, with either some rows OR "No Saved Website Data" is displayed!
					set prospectiveMatches to true
					repeat while prospectiveMatches
						delay 0.01
						
						if (count of (rows of myTable)) > 0 then
							--display notification "Found prospective junk for: '" & theJunkSpecifier & "'"
							exit repeat
						else
							try
								set uiChildren to entire contents of sheet 1
								
								repeat with theUIChild in uiChildren
									if class of theUIChild is static text and value of theUIChild contains "No Saved Website Data" then
										set prospectiveMatches to false
										exit repeat
									end if
								end repeat
							end try
						end if
					end repeat
					-- END WAIT (repeat while prospectiveMatches					
					
					set prospectiveJunkRows to count of (rows of myTable)
					set whiteListed to false
					set rowSite to ""
					set rowIndex to 1
					
					#Reset Scroll bar to TOP, incase Windos was alreasdy opened, and scrolled by User
					set value of scroll bar 1 of scroll area 1 of sheet 1 to 0
					
					# PROCESS ALL Lines MATCHING the junk specifier
					repeat while prospectiveJunkRows ³ rowIndex
						try
							set selectedRow to row rowIndex of myTable
							select selectedRow
							set rowSite to description of first UI element of selectedRow
							set domainName to first item of my textTokens(rowSite, space)
							
							if debugLog then
								log "-------- TOP"
								log "Cookie: '" & rowSite & "'"
								log "Domain: '" & domainName & "'"
								log "rowIndex: " & rowIndex as text
								log "prospectiveJunkRows: " & prospectiveJunkRows as text
								log "count of rows: " & (count of (rows of myTable)) as text
							end if
							
							-- AppleScript indexing is 1 based BUT item 0 maps to 1 so it can be confusing!
							-- SCROLL so selected row (as well as at least the prior and next rows) are in the VISIBLE Scroll port.
							repeat while (count of value of attribute "AXVisibleChildren" of row (my min(rowIndex + 1, prospectiveJunkRows)) of myTable) = 0
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
								
								# INTENTIONALLY not comparing equality when "*" found!
								if first character of whiteSite = "*" and last character of whiteSite = "*" then
									if domainName contains (text 2 through -2 of whiteSite) then
										log "Contains: " & (text 2 through -2 of whiteSite)
										set whiteListed to true
										exit repeat
									end if
								else if first character of whiteSite = "*" then
									if domainName ends with text 2 through -1 of whiteSite then
										log "Ends with: " & (text 2 through -1 of whiteSite)
										set whiteListed to true
										exit repeat
									end if
								else if last character of whiteSite = "*" then
									if domainName begins with text 1 through -2 of whiteSite then
										log "Begins with: " & (text 1 through -2 of whiteSite)
										set whiteListed to true
										exit repeat
									end if
								else if domainName is equal to whiteSite as text then
									log "Equals to: " & whiteSite
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
								
								# DELETE DATABASE first if present.
								if rowSite contains "Databases" then
									-- FIND & DELETE DATABASE file
									log domainName & ": Has Databases!"
									
									# Limiting GRIDINESS of conatins by prefixing a "." and "_"									
									set myFiles to (files of application "System Events"'s folder (databasesPath as text) where (name contains ("." & domainName)) or name contains ("_" & domainName))
									set myFiles to myFiles & (folders of application "System Events"'s folder (indexedDBPath as text) where (name contains ("." & domainName)) or name contains ("_" & domainName))
									
									repeat with theFile in myFiles
										log "Trash: " & name of theFile
										move theFile to application "System Events"'s trash
									end repeat
									-- END FIND & DELETE
								end if
								-- END DELETE DATABASE
								
								# DELETE COOCKIE!
								set repeatCount to 0
								repeat until (repeatCount > 10) or (prospectiveJunkRows > (count of (rows of myTable)))
									set repeatCount to repeatCount + 1
									
									# Because row may be last row and might have been deleted just after above <until...> was evaluated.
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
								
								if prospectiveJunkRows = (count of (rows of myTable)) then
									log "Failed deleting: " & rowSite
								end if
								-- END DELETE COOCKIE
							end if
						on error errorMessage number errorNumber from f to t partial result p
							--log "*** ERROR! " & errorMessage
							error errorMessage number errorNumber from f to t partial result p
						end try
						
						# Here instead of just after DELETE because it might also change outside of our control!
						set prospectiveJunkRows to count of (rows of myTable)
						
						if debugLog then
							log "-------- BOTTOM"
							log "Cookie: '" & rowSite & "'"
							log "Domain: '" & domainName & "'"
							log "rowIndex: " & rowIndex as text
							log "prospectiveJunkRows: " & prospectiveJunkRows as text
							log "count of rows: " & (count of (rows of myTable)) as text
						end if
					end repeat #while prospectiveJunkRows > rowIndex	
					-- END PROCESS ALL Lines MATCHING
				end repeat #with theJunkSpecifier in junkList
				-- ENND SEARCH
				
				click button "Done" of sheet 1
				
				# Don't like this style.
				--keystroke "w" using command down
				
				# This is hard coded but works
				--click button 1
				
				# WARNING: this line will FAIL upon removal of the () around <butons where...>
				# because the <where ...> clause will be wrongly applied the implied
				# <of windowPreferences> target instead of its <buttons> collection!	
				click button 1 of (buttons where role description = "close button")
			end tell #windowPreferences 
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