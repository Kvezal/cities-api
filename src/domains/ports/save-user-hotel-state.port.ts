import { FavoriteEntity } from '../entities';


export interface SaveUserHotelStatePort {
  saveUserHotelState(favoriteEntity: FavoriteEntity): FavoriteEntity;
}
