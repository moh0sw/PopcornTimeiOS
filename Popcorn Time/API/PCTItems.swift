

import Foundation

class PCTItem {
    let title: String
    let summary: String
    let torrents: [PCTTorrent]
    var currentTorrent: PCTTorrent!
    var subtitles: [PCTSubtitle]?
    var currentSubtitle: PCTSubtitle?
    var coverImageAsString: String!
    var id: String
    
    init (
        title: String,
        coverImageAsString: String?,
        id: String,
        torrents: [PCTTorrent],
        currentTorrent: PCTTorrent? = nil,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil,
        summary: String) {
        self.title = title
        self.coverImageAsString = coverImageAsString
        self.id = id
        self.torrents = torrents
        self.currentTorrent = currentTorrent
        self.subtitles = subtitles
        self.currentSubtitle = currentSubtitle
        self.summary = summary
    }
}

class PCTMovie: PCTItem {
    let rating: Float
    let genres: [String]
    let runtime: Int
    let trailorURLString: String
    let year: Int
    
    init(
        title: String,
        year: Int,
        coverImageAsString: String,
        imdbId: String,
        rating: Float,
        torrents: [PCTTorrent],
        currentTorrent: PCTTorrent? = nil,
        genres: [String],
        summary: String,
        runtime: Int,
        trailorURLString: String,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil) {
        self.rating = rating
        self.genres = genres
        self.year = year
        self.runtime = runtime
        self.trailorURLString = trailorURLString
        super.init(title: title, coverImageAsString: coverImageAsString, id: imdbId, torrents: torrents, currentTorrent: currentTorrent, subtitles: subtitles, currentSubtitle: currentSubtitle, summary: summary)
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n year: \"\(self.year)\"\n coverImageAsString:  \"\(self.coverImageAsString)\"\n imdbId: \"\(self.id)\"\n rating:  \"\(self.rating)\"\n torrents: \"\(self.torrents)\"\n genres: \"\(self.genres)\"\n summary: \"\(self.summary)\"\n runtime: \"\(self.runtime)\"\n trailorURLString: \"\(self.trailorURLString)\"\n"
        }
    }
}

struct PCTShow {
    var imdbId: String
    var title: String
    var year: String
    var coverImageAsString: String
    var rating: Float
    var genres: [String]?
    var status: String?
    var synopsis: String?
    var animeId: Int?
    
    init(
        imdbId: String,
        title: String,
        year: String,
        coverImageAsString: String,
        rating: Float,
        genres: [String]? = nil,
        status: String? = nil,
        synopsis: String? = nil,
        animeId: Int? = nil
        ) {
        self.imdbId = imdbId
        self.title = title
        self.year = year
        self.coverImageAsString = coverImageAsString
        self.rating = rating
        self.genres = genres
        self.status = status
        self.synopsis = synopsis
        self.animeId = animeId
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n year: \"\(self.year)\"\n coverImageAsString:  \"\(self.coverImageAsString)\"\n imdbId: \"\(self.imdbId)\"\n rating:  \"\(self.rating)\"\n genres: \"\(self.genres)\"\n status: \"\(self.status)\"\n synopsis: \"\(self.synopsis)\"\n"
        }
    }
}

class PCTEpisode: PCTItem {
    let season: Int
    let episode: Int
    var show: PCTShow?
    let airedDate: NSDate
    
    init(
        season: Int,
        episode: Int,
        title: String,
        summary: String,
        airedDate: NSDate,
        tvdbId: String,
        torrents: [PCTTorrent],
        currentTorrent: PCTTorrent? = nil,
        coverImageAsString: String? = nil,
        show: PCTShow? = nil,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil
        ) {
        self.season = season
        self.episode = episode
        self.show = show
        self.airedDate = airedDate
        super.init(title: title, coverImageAsString: coverImageAsString, id: tvdbId, torrents: torrents, currentTorrent: currentTorrent, subtitles: subtitles, currentSubtitle: currentSubtitle, summary: summary)
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n season: \"\(self.season)\"\n episode:  \"\(self.episode)\"\n summary: \"\(self.summary)\"\n airedDate: \"\(self.airedDate)\"\n"
        }
    }
}



struct PCTSubtitle: Equatable {
    let language: String
    let link: String
    let ISO639: String
    
    init(
        language: String,
        link: String,
        ISO639: String
        ) {
        self.language = language
        self.link = link
        self.ISO639 = ISO639
    }
    
     static func dictValue(subtitles: [PCTSubtitle]) -> [String: String] {
        var dict = [String: String]()
        for subtitle in subtitles {
            dict[subtitle.link] = subtitle.language
        }
        return dict
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> language: \"\(self.language)\"\n link: \"\(self.link)\"\n"
        }
    }
}

func ==(lhs: PCTSubtitle, rhs: PCTSubtitle) -> Bool {
    return lhs.link == rhs.link
}

struct PCTCastMetaData {
    let title: String
    let imageUrl: NSURL
    let contentType: String
    let duration: NSTimeInterval
    let subtitles: [PCTSubtitle]?
    let startPosition: NSTimeInterval
    let url: String
    let mediaAssetsPath: NSURL
    
    init(
        title: String,
        imageUrl: NSURL,
        contentType: String,
        duration: NSTimeInterval,
        subtitles: [PCTSubtitle]?,
        startPosition: NSTimeInterval,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.title = title
        self.imageUrl = imageUrl
        self.contentType = contentType
        self.duration = duration
        self.subtitles = subtitles
        self.startPosition = startPosition
        self.url = url
        self.mediaAssetsPath = mediaAssetsPath
    }
    
    init(
        movie: PCTMovie,
        duration: NSTimeInterval = 0,
        startPosition: NSTimeInterval,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.init(title: movie.title, imageUrl: NSURL(string: movie.coverImageAsString)!, contentType: "video/mp4", duration: duration, subtitles: movie.subtitles, startPosition: startPosition, url: url, mediaAssetsPath: mediaAssetsPath)
    }
    
    init(
        episode: PCTEpisode,
        duration: NSTimeInterval = 0,
        startPosition: NSTimeInterval,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.init(title: episode.title, imageUrl: NSURL(string: episode.show!.coverImageAsString)!, contentType: "video/x-matroska", duration: duration, subtitles: episode.subtitles, startPosition: startPosition, url: url, mediaAssetsPath: mediaAssetsPath)
    }
}
