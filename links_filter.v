// There are method related to text data operations, for now only stuff for links processing.
// The simpliest ways to resovle problems were used so probably better algorithms are needed in the future.
// I think this file should be separated in the text_processing.links namespace or something.

module text_processing

import regex

const links_regex_query = r'https' // ATTENTION: this is not valid regex, since we only using regex.find(), not regex.match(). A valid regex need to be used to find links after extraxt_links() method will be reimplemented.

// ATTENTION: this function will find only https links. Neither http nor other protocols will be found. This is because of HACK (next line).
//
// HACK: this function doesn't use regex.match() because of strange bug related to no matches in valid text with valid rule.
//       so regex.find() was used instead to find start of the link. End of the link is found by searching for the next ' ' or '\n' or '\r' or '\t' character.
//
// ATTENTION: This is not the best way to do it and it's produce invalid results sometimes (like instead of 'http://link.com/' it will return 'http://link.com>').
//
// TODO: reimplement this function using regex.match() (fix a bug in regex.match() first).
//
// Example
//
// Input:
//   ['LINK HERE -> https://link.com <- LINK HERE']
//
// Output:
//   ['https://link.com']

pub fn extract_links(messages []string) []string {
	mut links := []string{}

	mut links_regex := regex.regex_opt(text_processing.links_regex_query) or { panic(err) }

	for message in messages {
		start, _ := links_regex.find(message)

		if start != -1 {
			mut link_end := start

			for character in message[start..] {
				if character in [` `, `\n`, `\t`, `\r`] { // this is needed to handle different message formatings
					break
				}

				link_end += 1
			}

			links << message[start..link_end]
		}
	}

	return links
}

// Example
//
// Input:
//  ['https://link.com', 'https://www.facebook.com', 'https://www.google.com/www.facebook.com']
//  ['www.facebook.com']
//
// Output:
//  ['https://link.com', 'https://www.google.com/www.facebook.com']

pub fn filter_links_by_domains(links []string, unwanted_domains []string) []string {
	mut prepared_unwanted_domains := []string{}

	for domain in unwanted_domains {
		prepared_unwanted_domains << '://$domain' // this is needed to filter links related to this domain and not just contains this substring.
	}

	mut filtered_links := []string{}

	for link in links {
		if link.contains_any_substr(prepared_unwanted_domains) {
			continue
		}

		filtered_links << link
	}

	return filtered_links
}
