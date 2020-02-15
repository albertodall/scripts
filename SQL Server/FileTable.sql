SELECT 
	parent.name as Folder
	, child.name as [FileName]
	, child.is_directory, child.file_stream.GetFileNamespacePath() as FilePath
FROM 
	dbo.DocumentStore parent
	INNER JOIN dbo.DocumentStore child ON parent.path_locator = child.parent_path_locator
WHERE
	parent.name = 'Folder1'
