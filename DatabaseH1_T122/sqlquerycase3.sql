DROP DATABASE spojify

-- No. 1
INSERT INTO PlaylistHeader (PlaylistID, PlaylistOwner, CreatedDate)
VALUES ('PY000201', 'CU000101', '2023-02-10')

INSERT INTO PlaylistDetail (PlaylistID, SongID)
VALUES ('PY000201', 'SI000201')

INSERT INTO MsAlbum (AlbumID, AlbumOwner, AlbumName, AlbumPrice, AlbumGenre, AlbumPublishedDate)
VALUES ('AL000201', 'CU000002', 'Reputation', 125000, 'Pop', '2018-01-01')

INSERT INTO MsSong(SongID, SingerID, AlbumID, SongName, SongDuration)
VALUES ('SI000201', 'CU000002', 'AL000201', 'Gorgeous', 3)
GO

-- No. 2



UPDATE PlaylistHeader
SET CreatedDate = CONVERT(date, CURRENT_TIMESTAMP, 23)
WHERE RIGHT(PlayListID, 3) > '201'
AND PlaylistID IN(
	SELECT PlaylistID
	FROM PlaylistDetail WHERE SongID IN (
		SELECT SongID FROM MsSong WHERE AlbumID IN (
			SELECT AlbumID FROM MsAlbum WHERE AlbumGenre = 'Pop'
		)
	)
)

IF NOT EXISTS(

SELECT PlaylistID FROM PlaylistHeader
WHERE RIGHT(PlayListID, 3) > '201'
AND PlaylistID IN(
	SELECT PlaylistID
	FROM PlaylistDetail WHERE SongID IN (
		SELECT SongID FROM MsSong WHERE AlbumID IN (
			SELECT AlbumID FROM MsAlbum WHERE AlbumGenre = 'Pop'
		)
	)
)

)PRINT('NOTHING HAPPENED')


-- No. 3
SELECT SongName, AlbumName, CONCAT('Mr./Mrs.', userName) as [SingerName]
FROM MsSong JOIN MsAlbum ON MsSong.AlbumID = MsAlbum.AlbumID JOIN MsUser ON MsSong.SingerID =  MsUser.UserID
WHERE RIGHT(UserName, 3)='son'
UNION
SELECT SongName, AlbumName, CONCAT('Mr./Mrs.', UserName) as [SingerName]
FROM MsSong JOIN MsAlbum ON MsSong.AlbumID = MsAlbum.AlbumID JOIN MsUser ON MsSong.SingerID = MsUser.UserID
WHERE DATEDIFF(YEAR, CONVERT(DATE, CURRENT_TIMESTAMP), UserJoinedDate) = -3

-- No. 4
SELECT AlbumName, AlbumPrice
FROM MsAlbum ma JOIN MsUser mu ON mu.UserID = ma.AlbumOwner
WHERE AlbumPrice > (
	SELECT AVG(AlbumPrice)
	FROM MsAlbum
)AND UserEmail LIKE '%.com' AND UserEmail LIKE '%@%' AND UserEmail LIKE '%m%'


--No. 5
SELECT 
	LEFT(UserName, CHARINDEX(' ', UserName)) AS [First Name],
	pd.PlaylistID as [Playlist ID],
	COUNT(*) as PlaylistSongCount
FROM MsUser mu
JOIN PlaylistHeader ph ON mu.UserID = ph.PlaylistOwner
JOIN PlaylistDetail pd ON pd.PlaylistID = ph.PlaylistID
JOIN MsSong ms ON ms.SongID = pd.SongID
GROUP BY UserName, pd.PlaylistID
HAVING COUNT(*) > (
	SELECT AVG(SongCount.SongCount)
	FROM (
		SELECT COUNT(*) AS SongCount
		FROM MsUser mu
		JOIN PlaylistHeader ph ON mu.UserID = ph.PlaylistOwner
		JOIN PlaylistDetail pd ON pd.PlaylistID = ph.PlaylistID
		JOIN MsSong ms ON ms.SongID = pd.SongID
		GROUP BY UserName, pd.PlaylistID
	) SongCount
)
GO