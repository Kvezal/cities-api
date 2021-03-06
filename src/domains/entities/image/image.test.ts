import { ImageEntity } from './image.entity';
import { IImage } from './image.interface';


const imageParams: IImage = {
  id: `1`,
  title: `title`,
};

describe(`Image entity`, () => {
  describe(`constructor`, () => {
    let image: ImageEntity;

    beforeAll(() => {
      image = new ImageEntity(
        imageParams.id,
        imageParams.title,
      );
    });

    it.each([`id`, `title`])(`should create a new Image instance with correct %p property`, (property) => {
      expect(image[property]).toBe(imageParams[property]);
    });
  });

  describe(`create method`, () => {
    let image: ImageEntity;

    beforeAll(() => {
      image = ImageEntity.create(imageParams);
    });

    it(`should create a new Image instance`, () => {
      expect(image).toBeInstanceOf(ImageEntity);
    });

    it.each([`id`, `title`])(`should create a new Image instance with correct %p property`, (property) => {
      expect(image[property]).toBe(imageParams[property]);
    });
  })
});
