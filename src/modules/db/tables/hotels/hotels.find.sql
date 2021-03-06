SELECT
  hotels.id,
  hotels.title,
  hotels.description,
  hotels.bedroom_count,
  hotels.max_adult_count,
  FLOAT8(hotels.price) AS price,
  hotels.is_premium,
  TO_JSON(hotel_types) AS type,
  TO_JSON(locations) AS location,
  TO_JSON(users) AS host,
  TO_JSON(cities) AS city,
  image_list.value AS images,
  feature_list.value AS features,
  rating.value AS rating,
  favorite_flags.value AS is_favorite
FROM hotels
LEFT JOIN hotel_types ON hotels.hotel_type_id = hotel_types.id


LEFT JOIN (
  SELECT
    locations.id,
    ST_X(locations.coords) AS latitude,
    ST_Y(locations.coords) AS longitude,
    locations.zoom
  FROM locations
) AS locations ON hotels.location_id = locations.id


LEFT JOIN (
  SELECT
    users.id,
    users.email,
    users.name,
    user_types AS type,
    images AS image
  FROM users
  LEFT JOIN user_types ON users.user_type_id = user_types.id
  LEFT JOIN images ON users.image_id = images.id
) AS users ON hotels.host_id = users.id


LEFT JOIN (
  SELECT
    cities.id AS id,
    cities.title AS title,
    JSON_BUILD_OBJECT(
      'id', locations.id,
      'latitude', ST_X(locations.coords),
      'longitude', ST_Y(locations.coords),
      'zoom', locations.zoom
    ) AS location
  FROM cities
  LEFT JOIN locations ON cities.location_id = locations.id
) AS cities ON hotels.city_id = cities.id


LEFT JOIN (
  SELECT
    hotels.id AS hotel_id,
    COALESCE(
      JSON_AGG(images) FILTER (WHERE images IS NOT NULL), '[]'
    ) AS value
  FROM hotels
  LEFT JOIN hotels_images ON hotels.id = hotels_images.hotel_id
  LEFT JOIN images ON hotels_images.image_id = images.id
  GROUP BY hotels.id
) AS image_list ON hotels.id = image_list.hotel_id


LEFT JOIN (
  SELECT
    hotels.id AS hotel_id,
    COALESCE(
      JSON_AGG(features) FILTER (WHERE features IS NOT NULL), '[]'
    ) AS value
  FROM hotels
  LEFT JOIN hotels_features ON hotels.id = hotels_features.hotel_id
  LEFT JOIN features ON hotels_features.feature_id = features.id
  GROUP BY hotels.id
) AS feature_list ON hotels.id = feature_list.hotel_id


LEFT JOIN (
  SELECT
    hotels.id AS hotel_id,
    COALESCE(
      ROUND(AVG(ratings.value), 2),
      0
    )::FLOAT AS value
  FROM hotels
  LEFT JOIN ratings ON hotels.id = ratings.hotel_id
  GROUP BY hotels.id
) AS rating ON hotels.id = rating.hotel_id


LEFT JOIN (
  SELECT
    hotels.id AS hotel_id,
    COALESCE(COUNT(comments), 0)::INTEGER AS value
  FROM hotels
  LEFT JOIN comments ON hotels.id = comments.hotel_id
  GROUP BY hotels.id
) AS comment_counts ON hotels.id = comment_counts.hotel_id


LEFT JOIN (
  SELECT
    hotels.id AS hotel_id,
    COALESCE(COUNT(favorites), 0)::INTEGER AS value
  FROM hotels
  LEFT JOIN favorites ON hotels.id = favorites.hotel_id
  LEFT JOIN users ON favorites.user_id = users.id
  GROUP BY hotels.id
) AS favorite_counts ON hotels.id = favorite_counts.hotel_id


LEFT JOIN (
  SELECT
     hotels1.id AS hotel_id,
     ST_distance(
       locations1.coords, locations2.coords
     ) AS value
   FROM hotels AS hotels1
   LEFT JOIN hotels AS hotels2 ON hotels1.id != hotels2.id
   LEFT JOIN locations AS locations1 ON hotels2.location_id = locations1.id
   LEFT JOIN locations AS locations2 ON hotels1.location_id = locations2.id
   WHERE (:id != '' AND hotels2.id = :id::UUID)
) AS hotel_distances ON (hotels.id = hotel_distances.hotel_id) AND (:sorting = 'nearby')


LEFT JOIN (
  SELECT
    hotels.id AS hotel_id,
    (:user_id != '' AND EXISTS(
      SELECT *
      FROM favorites
      JOIN users ON users.id = favorites.user_id
        AND favorites.hotel_id = hotels.id
      WHERE users.id = :user_id::UUID
    )) AS value
  FROM hotels
) AS favorite_flags ON hotels.id = favorite_flags.hotel_id


WHERE
  (:id = '' OR (:sorting= 'nearby' AND hotels.id != :id::UUID) OR hotels.id = :id::UUID)
  AND (:title = '' OR hotels.title = :title)
  AND (:city::JSON->>'id' IS NULL OR :city::JSON->>'id' = '' OR cities.id = UUID(:city::JSON->>'id'))
  AND (:city::JSON->>'title' IS NULL OR :city::JSON->>'title' = '' OR cities.title = :city::JSON->>'title')
  AND (:is_favorite = FALSE OR favorite_flags.value)
  AND (:sorting != 'nearby' OR hotels.id != :id::UUID)
ORDER BY
  CASE
    WHEN (:sorting= 'rating')
      THEN rating.value
    WHEN (:sorting= 'high-price')
      THEN (hotels.price)
  END DESC,
  CASE
    WHEN (:sorting= 'low-price')
      THEN (hotels.price)
    WHEN (:sorting= 'nearby')
      THEN (hotel_distances.value)
  END ASC,
  ((favorite_counts.value + comment_counts.value) * rating.value) DESC;