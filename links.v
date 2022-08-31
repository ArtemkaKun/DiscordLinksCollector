// There is an implementation of links collecting logic from Discord. It based on REST request you can find in your browser (XHR tab).
// Maybe this is not hte best way to handle that kind of stuff but it's pretty simple and didn't require obtaining OAuth2 token from Discrod server,
// app registration and bla bla bla boring stuff.
//
// To make this code work you need to have a .env.discord file near an executable with the following content:
// AUTHORIZATION=... - you can have this token from any Discord XHR request in your browser
// GUILD_ID=... - id of your server (guild), also can be get probably from any XHR request
// CHANNEL_ID=... - same as two previous
//
// If you not sure what XHR is - I mean that funny stuff when you open a Discord in a browser, press f12, go to the Networking tab and reload the page.
// If you click on any, you will see a details of it, request data, response data, and more.
//
// This logic use Discord's search, so if Discord can't find a link (of fore some reasons doesn't add it to a search results) - it wouldn't be present here as well

module discord

import net.http
import zztkm.vdotenv
import os
import json
import time

const (
	artificial_sleep_time_in_seconds = 2 // This must be >= 2, because Discord can't handle request every second.
	discord_search_offset            = 25 // ATTENTION: don't change if you are not sure! Discord's search always returns 25 results per request.
)

struct SearchData {
	total_results u32
	messages      [][]MessageData
}

struct MessageData {
	content string
}

// Discord finds links in messages and returns not only links but whole message.
// So returned strings can be something like "WOW LOOK AT THIS STUFF - https://discord.gg/123456789"
pub fn get_messages_with_links() []string {
	mut messages := []string{}

	vdotenv.load('.env.discord')

	search_response := send_search_links_request(0) or {
		panic('Failed to send first search links request - $err')
	}

	search_data := get_search_data_from_response(search_response)
	messages << get_messages_from_search_data(search_data)

	search_results_count := search_data.total_results
	mut current_offset := 0

	for current_offset + discord.discord_search_offset < search_results_count {
		current_offset += discord.discord_search_offset
		messages << get_messages(current_offset) or { continue }
	}

	return messages
}

// This method actually have an artificial thread sleep (defined by artificial_sleep_time_in_seconds) before sending a request,
// because Discord can't handle too many requests in a short time.
//
// ATTENTION: You must load your GUILD_ID, CHANNEL_ID and AUTHORIZATION enviroment variables before calling this function.
//
// TIP: Provide 0 as offset to get first page of results
fn send_search_links_request(offset int) ?http.Response {
	mut request := http.Request{
		method: .get
		url: 'https://discord.com/api/v10/guilds/${os.getenv('GUILD_ID')}/messages/search?channel_id=${os.getenv('CHANNEL_ID')}&has=link&offset=$offset'
	}

	request.add_header(.authorization, os.getenv('AUTHORIZATION'))

	// HACK: Mandatory sleep before sending a request because of Discord's limitations.
	artificial_sleep_thread := go sleep_in_seconds(discord.artificial_sleep_time_in_seconds)
	artificial_sleep_thread.wait()

	return request.do()
}

fn sleep_in_seconds(seconds int) {
	time.sleep(seconds * time.second)
}

// Since response's body in a JSON form, we need to parse it. No need to decompress because Accept-Encoding header is not set.
fn get_search_data_from_response(response http.Response) SearchData {
	return json.decode(SearchData, response.body) or {
		panic('Failed to decode response body -> SearchData - $err')
	}
}

// Extracts content of a message - this can be confusing since Discord sends {total_results, messages} JSON object,
// but message - it's an array of message's data, not a message itself.
//
// Example:
//
// Input:
// {
//   "total_results": 1,
//   "messages": [
//		[
//			{
//				"content": "WOW LOOK AT THIS STUFF - https://discord.gg/123456789"
//			}
//		]
//   ]
// }
//
// Output:
// ['WOW LOOK AT THIS STUFF - https://discord.gg/123456789']

fn get_messages_from_search_data(search_data SearchData) []string {
	mut messages := []string{}

	for message in search_data.messages {
		messages << message[0].content
	}

	return messages
}

fn get_messages(offset int) ?[]string {
	response := send_search_links_request(offset) or {
		panic('Failed to send search links request - $err')
	}

	search_data := get_search_data_from_response(response)

	return get_messages_from_search_data(search_data)
}
