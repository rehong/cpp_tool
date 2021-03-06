# Part5 曲库管理

## 5.1. 创建曲库接口

### HTTP请求

`post /api/v1/tracks`

### file_type:(0:图片,1:歌曲文件,2:歌词,3:视频)
### Request 请求参数

```json
{
 "track": {
	 "title": "genre",
	 "language_id": 1,
	 "genre": "folk",
	 "label": "sdsdfsdf",
	 "isrc": "isrc",
	 "ost": "ost",
	 "remark": "sfdsdfnsfksnvksnvkjnvkjnv",
	 "album_ids" : [1],
   "primary_artist_ids": [7],
   "featuring_artist_ids": [8],
	 "provider_id": 1,
	 "contract_id": 1,
	 "authorize_id": 2,
	 "is_agent": true,
	 "track_composers_attributes": [{ "op_type": "作词","name": "taihe", "point": 1}],
	 "track_resources_attributes":[{"file_type": 1,"url": "fdfdfd","file_name": "rrrr"}]
 }
}

```
### Response 响应

```json
{
	"track": {
		"title": "genre",
	 "language_id": 1,
	 "genre": "folk",
	 "label": "sdsdfsdf",
	 "isrc": "isrc",
	 "ost": "ost",
	 "remark": "sfdsdfnsfksnvksnvkjnvkjnv",
	 "album_name": "dfdfdf",
	 "artist_name": "dfdf",
	 "provider_name": "dfdfd"
	}
}

```

## 5.2. 删除曲库接口

### HTTP请求

`delete /api/v1/tracks/:id`

### Request 请求参数


| 参数名  | 是否必需 | 描述   |
| ---- | ---- | ---- |
| id   | 是    | 曲库ID |


### Response 响应

> 响应数据:

## 3.3. 更新曲库接口

### HTTP请求

`put /api/v1/tracks/:id`


```json
{
 "track": {
	 "id":1,
	"title": "genre",
	"language_id": 1,
	"genre": "folk",
	"label": "sdsdfsdf",
  "label_code": "sdsdfsdf",
	"isrc": "isrc",
	"ost": "ost",
	"remark": "sfdsdfnsfksnvksnvkjnvkjnv",
	"album_ids" : [1],
	"provider_id": 1,
	"contract_id": 1,
	"authorize_id": 2,
	"is_agent": true,
  "primary_artist_ids": [7],
  "featuring_artist_ids": [8],
	"track_composers_attributes": [{ "id":1,"op_type": "作词","name": "taihe", "point": 1,"_destroy": true}],
  "track_resources_attributes":[{"id":1,"file_type": 1,"url": "fdfdfd","file_name": "rrrr","_destroy": true}]
 }
}
```
### Response 响应

```json
{
	"track": {
		 "title": "genre",
		"language_id": 1,
		"genre": "folk",
		"label": "sdsdfsdf",
		"isrc": "isrc",
		"ost": "ost",
		"remark": "sfdsdfnsfksnvksnvkjnvkjnv",
		"album_name": "dfdfdf",
		"artist_name": "dfdf",
		"provider_name": "dfdfd"
  }
}

```

## 5.4. 查询曲库列表接口

### HTTP请求

`get /api/v1/tracks?size=2&page=1`

### Request 请求参数


| 参数名  | 是否必需 | 描述      |
| ---- | ---- | ------- |
| size | 是    | 每页显示的条数 |
| page | 否    | 第几页     |

#### 请求示例

`get /api/v1/tracks?size=2&page=1`

### Response 响应

> 响应数据:

```json
{
  "tracks": [
		{
			"title": "genre",
		 "language_id": 1,
		 "genre": "folk",
		 "label": "sdsdfsdf",
     "label_code" : "dfdf",
		 "isrc": "isrc",
		 "ost": "ost",
		 "remark": "sfdsdfnsfksnvksnvkjnvkjnv",
		 "album_name": "dfdfdf",
		 "artist_name": "dfdf",
		 "provider_name": "dfdfd"
   }
  ],
  "meta": {
    "page": 1,
    "total": 6
  }
}
```




## 5.5. 查看曲库接口

### HTTP请求

`get /api/v1/tracks/1`

### Response 响应

> 响应数据:

```json
{
  "tracks":
		{
			"title": "genre",
		 "language_id": 1,
		 "genre": "folk",
		 "label": "sdsdfsdf",
		 "isrc": "isrc",
		 "ost": "ost",
		 "remark": "sfdsdfnsfksnvksnvkjnvkjnv",
		 "albums":[{"name":"dfdf"}],
		 "primary_artists": [{"name":"dfdf"}],
		 "provider_name": "dfdfd",
		 "provider_id":1,
		 "contract_id":1,
		 "authorize_id":1,
		 "track_composers":[{"name":"232332","point":1,"op_type":"作曲"}],
		 "track_resources":[{"file_type":1,"url":"dfdfd","file_name":"dfdfdf"}]
   }

}
```


### Response 响应

> 响应数据:
null



## 5.6、审核不通过版

### HTTP请求

`POST  /api/v1/tracks/:id/reject`

### Request 请求参数

| 参数名    | 是否必需 | 描述    |
| ------ | ---- | ----- |
| id   | 是    | 版权方id |
| not_through_reason  |  是    |  未通过原因 |

### Request 请求

```json
{
 "id": 1,
 "not_through_reason": "dddd"
}

```
### Response 响应

> 响应数据:
null


## 5.7、批量审核通过

### HTTP请求

`POST  /api/v1/tracks/accept`

### Request 请求参数

| 参数名    | 是否必需 | 描述    |
| ------ | ---- | ----- |
| track_ids   | 是    | 版权方id |


### Request 请求

```json
{
 "track_ids": [1,2]
}

```
### Response 响应

> 响应数据:
null
