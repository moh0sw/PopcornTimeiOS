

import Foundation

class PCTItem: NSObject {
    let title: String
    let summary: String
    var torrents: [PCTTorrent]!
    var currentTorrent: PCTTorrent!
    var subtitles: [PCTSubtitle]?
    var currentSubtitle: PCTSubtitle?
    var coverImageAsString: String?
    var backgroundImageAsString: String?
    var id: String
    
    init (
        title: String,
        coverImageAsString: String?,
        backgroundImageAsString: String?,
        id: String,
        torrents: [PCTTorrent],
        currentTorrent: PCTTorrent? = nil,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil,
        summary: String) {
        self.title = title
        self.coverImageAsString = coverImageAsString
        self.backgroundImageAsString = backgroundImageAsString
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
    let runtime: String
    let trailerURLString: String?
    let year: String
    
    init(
        title: String,
        year: String,
        coverImageAsString: String?,
        backgroundImageAsString: String?,
        imdbId: String,
        rating: Float,
        torrents: [PCTTorrent]? = nil,
        currentTorrent: PCTTorrent? = nil,
        genres: [String],
        summary: String,
        runtime: String,
        trailerURLString: String?,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil) {
        self.rating = rating
        self.genres = genres
        self.year = year
        self.runtime = runtime
        self.trailerURLString = trailerURLString
        super.init(title: title, coverImageAsString: coverImageAsString, backgroundImageAsString: backgroundImageAsString, id: imdbId, torrents: torrents ?? [], currentTorrent: currentTorrent, subtitles: subtitles, currentSubtitle: currentSubtitle, summary: summary)
    }
    
    override var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n year: \"\(self.year)\"\n coverImageAsString:  \"\(self.coverImageAsString)\"\n imdbId: \"\(self.id)\"\n rating:  \"\(self.rating)\"\n torrents: \"\(self.torrents)\"\n genres: \"\(self.genres)\"\n summary: \"\(self.summary)\"\n runtime: \"\(self.runtime)\"\n trailorURLString: \"\(self.trailerURLString)\"\n"
        }
    }
}

class PCTShow: NSObject {
    var id: String
    var title: String
    var year: String
    var coverImageAsString: String?
    var backgroundImageAsString: String?
    var rating: Float
    var genres: [String]?
    var status: String?
    var synopsis: String?
    let slug: String
    
    init(
        id: String,
        title: String,
        year: String,
        coverImageAsString: String?,
        backgroundImageAsString: String?,
        rating: Float,
        slug: String,
        genres: [String]? = nil,
        status: String? = nil,
        synopsis: String? = nil
        ) {
        self.id = id
        self.title = title
        self.year = year
        self.coverImageAsString = coverImageAsString
        self.backgroundImageAsString = backgroundImageAsString
        self.rating = rating
        self.slug = slug
        self.genres = genres
        self.status = status
        self.synopsis = synopsis
    }
    
    override var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n year: \"\(self.year)\"\n coverImageAsString:  \"\(self.coverImageAsString)\"\n id: \"\(self.id)\"\n rating:  \"\(self.rating)\"\n genres: \"\(self.genres)\"\n status: \"\(self.status)\"\n synopsis: \"\(self.synopsis)\"\n"
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
        backgroundImageAsString: String? = nil,
        show: PCTShow? = nil,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil
        ) {
        self.season = season
        self.episode = episode
        self.show = show
        self.airedDate = airedDate
        super.init(title: title, coverImageAsString: coverImageAsString, backgroundImageAsString: backgroundImageAsString, id: tvdbId, torrents: torrents, currentTorrent: currentTorrent, subtitles: subtitles, currentSubtitle: currentSubtitle, summary: summary)
    }
    
    override var description: String {
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
    let imageUrl: NSURL?
    let contentType: String
    let subtitles: [PCTSubtitle]?
    let url: String
    let mediaAssetsPath: NSURL
    
    init(
        title: String,
        imageUrl: NSURL?,
        contentType: String,
        subtitles: [PCTSubtitle]?,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.title = title
        self.imageUrl = imageUrl
        self.contentType = contentType
        self.subtitles = subtitles
        self.url = url
        self.mediaAssetsPath = mediaAssetsPath
    }
    
    init(
        movie: PCTMovie,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.init(title: movie.title, imageUrl: movie.coverImageAsString != nil ? NSURL(string: movie.coverImageAsString!) : nil, contentType: "video/mp4", subtitles: movie.subtitles, url: url, mediaAssetsPath: mediaAssetsPath)
    }
    
    init(
        episode: PCTEpisode,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.init(title: episode.title, imageUrl: episode.show?.coverImageAsString != nil ? NSURL(string: episode.show!.coverImageAsString!) : nil, contentType: "video/x-matroska", subtitles: episode.subtitles, url: url, mediaAssetsPath: mediaAssetsPath)
    }
}

struct PCTActor {
    let imdbId: String?
    let slug: String
    let imageAsString: String?
    let name: String
    let character: String
    
    init(
        imdbId: String?,
        slug: String,
        imageAsString: String?,
        name: String,
        character: String
        ) {
        self.imdbId = imdbId
        self.slug = slug
        self.imageAsString = imageAsString
        self.name = name
        self.character = character
    }
}
