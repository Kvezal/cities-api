import { LocationEntity } from '../location';
import { ICity } from './city-interface';


export class CityEntity {
  constructor(
    private readonly _id: number,
    private readonly _title: string,
    private readonly _location: LocationEntity
  ) {}

  get id(): number {
    return this._id;
  }

  get title(): string {
    return this._title;
  }

  get location(): LocationEntity {
    return this._location;
  }

  static create(params: ICity): CityEntity {
    return new CityEntity(
      params.id,
      params.title,
      LocationEntity.create(params.location)
    );
  }
}