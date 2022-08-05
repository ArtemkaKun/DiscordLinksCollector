module text_processing

fn test_extract_links() {
	input := ['LINK HERE -> https://test.com <- LINK HERE']
	output := extract_links(input)

	assert output[0] == 'https://test.com'
}

fn test_filter_links_by_host() {
	input := [
		'https://tenor.com/view/mindblown-amazed-explosion-space-omg-gif-10279314',
	]
	output := filter_links_by_host(input, ['tenor.com', 'giphy.com'])

	assert output.len == 0
}
