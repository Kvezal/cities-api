import { HotelEntity } from 'domains/entities';


export interface GetHotelByIdQuery {
  getHotelById(hotelId: string): Promise<HotelEntity>;
}
