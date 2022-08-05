module main

import discord
import text_processing
import os

fn main() {
	messages_with_links := discord.get_messages_with_links()
	links := text_processing.extract_links(messages_with_links)

	filtered_links := text_processing.filter_links_by_domains(links, [
		'www.kickstarter.com',
		'www.pepper.pl',
		'tenor.com',
		'www.wykop.pl',
		'giphy.com',
	])

	os.create('links.txt') or { panic(err) }
	os.write_file('links.txt', filtered_links.join_lines()) or { panic(err) }
}
