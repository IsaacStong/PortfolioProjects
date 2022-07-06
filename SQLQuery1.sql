SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- COUNTRY

-- Total Cases vs. Total Deaths
-- Rough Estimate of likelihood of death if Covid is contracted today (doesn't take into account vaccinated vs. unvaccinated)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1, 2;

--Total Cases vs. Population
-- Shows % of population that has had covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
AND location = 'United States'
ORDER BY 1, 2;

--Looking for large countries with highest infection rates
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING population >= 1000000
ORDER BY 4 DESC;

--Looking for highest death counts and their adjacent death percentage to the population of the country
SELECT location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, ROUND(MAX((CAST(total_deaths AS INT)/CAST(population AS FLOAT)))*100, 3) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

-- COUNTRY

-- World and Continents with highest death counts
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Number of people vaccinated (rolling count) with percentage using CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccineCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccineCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccines vac
	ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ((RollingVaccineCount/CAST(Population AS FLOAT)) / 2)*100 AS PercentFully1Vaccinated
FROM PopVsVac;

--GLOBAL

--World Death Count, Infection Count, Death Percent, Infection Percent
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount, MAX(CAST(total_cases AS INT)) AS TotalCaseCount, (MAX(CAST(total_deaths AS INT))/MAX(CAST(total_cases AS FLOAT)))*100 AS CaseDeathPercentage,
	(MAX(CAST(total_deaths AS INT))/MAX(CAST(population AS FLOAT)))*100 AS PopulationDeathPercentage, (MAX(CAST(total_cases AS INT))/MAX(CAST(population AS FLOAT)))*100 AS PopulationCasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'World'
GROUP BY location;

--VIEWS

CREATE VIEW PercentPopulatedVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccineCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccines vac
	ON dea.location = vac.location
		AND dea.date = vac.date